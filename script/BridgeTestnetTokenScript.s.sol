// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {SendParam, MessagingFee, OFTReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {IStargate} from "@stargatefinance/stg-evm-v2/src/interfaces/IStargate.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UniversalComposer} from "../src/UniversalComposer.sol";

// Stargate does not support amoy testnet, so we use Arbitrum Sepolia -> Optimism Sepolia instead.
contract BridgeTestnetTokenScript is Script {
    using OptionsBuilder for bytes;

    // Endpoint addresses
    address constant arbitrumSepoliaEndpoint =
        0x6EDCE65403992e310A62460808c4b910D972f10f;
    address constant optimismSepoliaEndpoint =
        0x6EDCE65403992e310A62460808c4b910D972f10f;

    address constant usdcArbitrumSepolia =
        0x3253a335E7bFfB4790Aa4C25C4250d206E9b9773;
    address constant stargatePoolUSDCArbitrumSepolia =
        0x0d7aB83370b492f2AB096c80111381674456e8d8; // StargatePoolUSDC Arbitrum Sepolia

    address constant usdtArbitrumSepolia =
        0x3C0Dea5955cb490F78e330A213c960cA63f66314;
    address constant stargatePoolUSDTArbitrumSepolia =
        0xC48c0736C8ae67A8C54DFb01D7ECc7190C12a042; // StargatePoolUSDT Arbitrum Sepolia

    address constant usdcOptimismSepolia =
        0x488327236B65C61A6c083e8d811a4E0D3d1D4268;
    address constant stargatePoolUSDCOptimismSepolia =
        0x1E8A86EcC9dc41106d3834c6F1033D86939B1e0D; // StargatePoolUSDC Optimism Sepolia

    address constant usdtOptimismSepolia =
        0x9352001271a0af0d09a4e7F6C431663A2D5AA9d2;
    address constant stargatePoolUSDTOptimismSepolia =
        0x0d7aB83370b492f2AB096c80111381674456e8d8; // StargatePoolUSDT Optimism Sepolia

    uint32 constant arbsep_v2_testnet = 40231;
    uint32 constant optsep_v2_testnet = 40232;

    function setUp() public {}

    function run(
        address composer,
        uint128 _executorLzComposeGasLimit,
        string memory _composeMsg
    ) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address sender = vm.addr(deployerPrivateKey);

        uint256 amount = 3;

        IERC20(usdtArbitrumSepolia).approve(
            stargatePoolUSDTArbitrumSepolia,
            amount
        );

        (bool success, bytes memory data) = usdtArbitrumSepolia.call{
            value: 0,
            gas: 52000
        }(abi.encodeWithSignature("mint(address,uint256)", sender, amount));
        console.log("success: %s", success);
        console.logBytes(data);

        uint256 usdtBalance = IERC20(usdtArbitrumSepolia).balanceOf(msg.sender);

        console.log(usdtBalance);

        require(usdtBalance >= amount, "Insufficient USDT balance");

        console.logBytes(fromHex(_composeMsg));

        (
            uint256 valueToSend,
            SendParam memory sendParam,
            MessagingFee memory messagingFee
        ) = prepareTakeTaxiAndAMMSwap(
                stargatePoolUSDTArbitrumSepolia,
                optsep_v2_testnet,
                amount,
                address(composer),
                _executorLzComposeGasLimit,
                fromHex(_composeMsg)
            );

        console.log("valueToSend (value param in Tx)", valueToSend);
        console.log("min amount received", sendParam.minAmountLD);

        IStargate(stargatePoolUSDTArbitrumSepolia).sendToken{
            value: valueToSend
        }(sendParam, messagingFee, msg.sender);

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

        IStargate stargate = IStargate(_stargate);

        (, , OFTReceipt memory receipt) = stargate.quoteOFT(sendParam);
        sendParam.minAmountLD = receipt.amountReceivedLD;
        console.log("min amount received", sendParam.minAmountLD);

        messagingFee = stargate.quoteSend(sendParam, false);
        valueToSend = messagingFee.nativeFee;

        if (stargate.token() == address(0x0)) {
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
