// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ILayerZeroComposer} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroComposer.sol";
import {OFTComposeMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";
import {IOFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {Withdrawable} from "./utils/Withdrawable.sol";

contract UniversalComposer is ILayerZeroComposer, Pausable, Withdrawable {
    struct Operation {
        address to;
        uint256 value;
        bytes data;
    }

    uint256 public fee = 0;

    address public immutable endpoint;
    address public immutable stargateOApp;

    event ReceivedOnDestination(
        address token,
        uint256 amount,
        bytes _extraData
    );

    /// @notice Emitted whenever a transaction is processed successfully from this wallet. Includes
    ///  both simple send ether transactions, as well as other smart contract invocations.
    /// @param numOperations A count of the number of operations processed
    event InvocationSuccess(uint256 numOperations);

    constructor(
        address _endpoint,
        address _stargateOApp
    ) Withdrawable() Pausable() {
        endpoint = _endpoint;
        stargateOApp = _stargateOApp;
    }

    function lzCompose(
        address _from,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external payable whenNotPaused {
        require(_from == stargateOApp, "_from should be the StargateOApp.");
        require(
            msg.sender == endpoint,
            "Can only be called by LayerZero endpoint."
        );

        uint256 amountLD = OFTComposeMsgCodec.amountLD(_message);
        bytes memory _composeMessage = OFTComposeMsgCodec.composeMsg(_message);

        emit ReceivedOnDestination(
            IOFT(stargateOApp).token(),
            amountLD,
            _extraData
        );

        if (fee > 0) {
            IERC20(IOFT(stargateOApp).token()).transfer(owner(), fee);
        }

        internalInvokeCall(_composeMessage);
    }

    /// @dev Internal invoke call,
    /// @param data The data to send to the `call()` operation
    function internalInvokeCall(bytes memory data) internal {
        // At an absolute minimum, the data field must be at least 84 bytes
        // <to_address(20), value(32), data_length(32)>
        require(data.length >= 84, "data field too short");

        // keep track of the number of operations processed
        uint256 numOps;

        // We need to store a reference to this string as a variable so we can use it as an argument to
        // the revert call from assembly.
        string memory invalidLengthMessage = "data field too short";
        string memory callFailed = "call failed";

        // At an absolute minimum, the data field must be at least 85 bytes
        // <to_address(20), value(32), data_length(32)>

        // Forward the call onto its actual target. Note that the target address can be `self` here, which is
        // actually the required flow for modifying the configuration of the authorized keys and recovery address.
        //
        // The assembly code below loads data directly from memory, so the enclosing function must be marked `internal`
        assembly {
            // A cursor pointing to the content of the data object, starts after the length field of the data object
            let memPtr := add(data, 32)

            // A pointer to the end of the data object
            let endPtr := add(memPtr, mload(data))

            // Loop through data, parsing out the various sub-operations
            for {

            } lt(memPtr, endPtr) {

            } {
                // Load the length of the call data of the current operation
                // 52 = to(20) + value(32)
                let len := mload(add(memPtr, 52))

                // Compute a pointer to the end of the current operation
                // 84 = to(20) + value(32) + size(32)
                let opEnd := add(len, add(memPtr, 84))

                // Bail if the current operation's data overruns the end of the enclosing data buffer
                // NOTE: Comment out this bit of code and uncomment the next section if you want
                // the solidity-coverage tool to work.
                // See https://github.com/sc-forks/solidity-coverage/issues/287
                if gt(opEnd, endPtr) {
                    // The computed end of this operation goes past the end of the data buffer. Not good!
                    revert(
                        add(invalidLengthMessage, 32),
                        mload(invalidLengthMessage)
                    )
                }
                // NOTE: Code that is compatible with solidity-coverage
                // switch gt(opEnd, endPtr)
                // case 1 {
                //     revert(add(invalidLengthMessage, 32), mload(invalidLengthMessage))
                // }

                // This line of code packs in a lot of functionality!
                //  - load the target address from memPtr, the address is only 20-bytes but mload always grabs 32-bytes,
                //    so we have to shr by 12 bytes.
                //  - load the value field, stored at memPtr+20
                //  - pass a pointer to the call data, stored at memPtr+84
                //  - use the previously loaded len field as the size of the call data
                //  - make the call (passing all remaining gas to the child call)
                if eq(
                    0,
                    call(
                        gas(),
                        shr(96, mload(memPtr)),
                        mload(add(memPtr, 20)),
                        add(memPtr, 84),
                        len,
                        0,
                        0
                    )
                ) {
                    revert(add(callFailed, 32), mload(callFailed))
                }

                // increment our counter
                numOps := add(numOps, 1)

                // Update mem pointer to point to the next sub-operation
                memPtr := opEnd
            }
        }

        // emit single event upon success
        emit InvocationSuccess(numOps);
    }

    function encodeOperation(
        Operation[] memory _operations
    ) external pure returns (bytes memory _data) {
        // concate all encode packed operations into bytes in assembly
        // bytes memory _data;
        for (uint256 i = 0; i < _operations.length; i++) {
            _data = abi.encodePacked(
                _data,
                abi.encodePacked(
                    _operations[i].to,
                    _operations[i].value,
                    _operations[i].data.length,
                    _operations[i].data
                )
            );
        }
    }

    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    fallback() external payable {}

    receive() external payable {}
}
