// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Script.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {MessagingReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import {SendParam, OFTReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {IStargate} from "@stargatefinance/stg-evm-v2/src/interfaces/IStargate.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UniversalComposer} from "../src/UniversalComposer.sol";

contract BridgeMainnetTokenScript is Script {
    using OptionsBuilder for bytes;

    // Endpoint addresses
    address constant arbitrumEndpoint =
        0x1a44076050125825900e736c501f859c50fE728c;
    address constant polygonEndpoint =
        0x1a44076050125825900e736c501f859c50fE728c;

    address constant usdtArbitrum = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant stargatePoolUSDTArbitrum =
        0xcE8CcA271Ebc0533920C83d39F417ED6A0abB7D0; // StargatePoolUSDT Arbitrum Sepolia

    address constant usdtPolygon = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address constant stargatePoolUSDTPolygon =
        0xd47b03ee6d86Cf251ee7860FB2ACf9f91B9fD4d7; // StargatePoolUSDT Optimism Sepolia

    uint32 constant v2_arb = 30110;
    uint32 constant v2_polygon = 30109;

    function run(
        address composer,
        uint128 _executorLzComposeGasLimit,
        string memory _composeMsg
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("msg.sender", msg.sender);

        uint256 _tokenOut = 100;

        IERC20(usdtArbitrum).approve(stargatePoolUSDTArbitrum, _tokenOut);

        uint256 usdtBalance = IERC20(usdtArbitrum).balanceOf(msg.sender);

        console.log(usdtBalance);

        require(usdtBalance >= _tokenOut, "Insufficient USDT balance");

        console.logBytes(fromHex(_composeMsg));

        (
            uint256 valueToSend,
            SendParam memory sendParam,
            MessagingFee memory messagingFee
        ) = prepareTakeTaxiAndAMMSwap(
                stargatePoolUSDTArbitrum,
                v2_polygon,
                _tokenOut,
                composer,
                _executorLzComposeGasLimit,
                fromHex(_composeMsg)
            );

        console.log(valueToSend);

        IStargate(stargatePoolUSDTArbitrum).sendToken{value: valueToSend}(
            sendParam,
            messagingFee,
            msg.sender
        );

        vm.stopBroadcast();
    }

    function prepareTakeTaxiAndAMMSwap(
        address _stargate,
        uint32 _dstEid,
        uint256 _amount,
        address _composer,
        uint128 _executorLzComposeGasLimit,
        bytes memory _composeMsg
    )
        internal
        view
        returns (
            uint256 valueToSend,
            SendParam memory sendParam,
            MessagingFee memory messagingFee
        )
    {
        bytes memory extraOptions = _composeMsg.length > 0
            ? OptionsBuilder.newOptions().addExecutorLzComposeOption(
                0,
                _executorLzComposeGasLimit,
                0
            ) // compose gas limit
            : bytes("");

        sendParam = SendParam({
            dstEid: _dstEid,
            to: addressToBytes32(_composer),
            amountLD: _amount,
            minAmountLD: _amount,
            extraOptions: extraOptions,
            composeMsg: _composeMsg,
            oftCmd: "" // taxi mode should be _oftCmd.length == 0, and composeMsg can only be support by taxi mode
        });

        IStargate iStargate = IStargate(_stargate);

        (, , OFTReceipt memory receipt) = iStargate.quoteOFT(sendParam);
        sendParam.minAmountLD = receipt.amountReceivedLD;

        console.log("sendParam.minAmountLD", sendParam.minAmountLD);

        messagingFee = iStargate.quoteSend(sendParam, false);
        valueToSend = messagingFee.nativeFee;

        if (iStargate.token() == address(0x0)) {
            valueToSend += sendParam.amountLD;
        }
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function fromHexChar(uint8 c) public pure returns (uint8) {
        if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
            return c - uint8(bytes1("0"));
        }
        if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
            return 10 + c - uint8(bytes1("a"));
        }
        if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
            return 10 + c - uint8(bytes1("A"));
        }
        revert("fail");
    }

    function fromHex(string memory s) public pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length % 2 == 0); // length must be even
        bytes memory r = new bytes(ss.length / 2);
        for (uint i = 0; i < ss.length / 2; ++i) {
            r[i] = bytes1(
                fromHexChar(uint8(ss[2 * i])) *
                    16 +
                    fromHexChar(uint8(ss[2 * i + 1]))
            );
        }
        return r;
    }
}
