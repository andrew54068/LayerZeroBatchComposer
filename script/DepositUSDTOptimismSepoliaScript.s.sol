// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {MockUSDT} from "../src/MockUSDT.sol";
import {MockYearnV3Vault} from "../src/MockYearnV3Vault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStargatePool} from "@stargatefinance/stg-evm-v2/src/interfaces/IStargatePool.sol";

contract DepositUSDTOptimismSepoliaScript is Script {
    address constant usdtOptimismSepolia =
        0x9352001271a0af0d09a4e7F6C431663A2D5AA9d2;
    address constant stargatePoolUSDTOptimismSepolia =
        0x0d7aB83370b492f2AB096c80111381674456e8d8; // StargatePoolUSDT Optimism Sepolia

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address sender = vm.addr(deployerPrivateKey);

        uint256 amount = 10000 ether;

        (bool success, bytes memory data) = usdtOptimismSepolia.call{
            value: 0,
            gas: 52000
        }(abi.encodeWithSignature("mint(address,uint256)", sender, amount));
        console.log("success: %s", success);
        console.logBytes(data);

        IERC20(usdtOptimismSepolia).approve(
            stargatePoolUSDTOptimismSepolia,
            amount
        );

        IStargatePool(stargatePoolUSDTOptimismSepolia).deposit(
            address(msg.sender),
            amount
        );

        vm.stopBroadcast();
    }
}
