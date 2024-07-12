// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {MockUSDT} from "../src/MockUSDT.sol";
import {MockYearnV3Vault} from "../src/MockYearnV3Vault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DepositMockedYearnV3Script is Script {
    address constant usdtOptimismSepolia =
        0x9352001271a0af0d09a4e7F6C431663A2D5AA9d2;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address sender = vm.addr(deployerPrivateKey);

        MockYearnV3Vault mockYearnV3Vault = new MockYearnV3Vault(
            usdtOptimismSepolia
        );

        uint256 amount = 10000;

        // https://sepolia-optimism.etherscan.io/tx/0x4d2660f0698f996067adf702fb257ccd515e5a5d580cfaad6f5631955433fbc5
        (bool success, bytes memory data) = usdtOptimismSepolia.call{
            value: 0,
            gas: 52000
        }(abi.encodeWithSignature("mint(address,uint256)", sender, amount));
        console.log("success: %s", success);
        console.logBytes(data);

        IERC20(usdtOptimismSepolia).approve(address(mockYearnV3Vault), amount);

        mockYearnV3Vault.deposit(amount, address(msg.sender));

        vm.stopBroadcast();
    }
}
