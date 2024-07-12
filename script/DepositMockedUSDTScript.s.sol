// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {MockUSDT} from "../src/MockUSDT.sol";
import {MockYearnV3Vault} from "../src/MockYearnV3Vault.sol";

contract DepositMockedUSDTScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        MockUSDT mockUSDT = new MockUSDT();
        MockYearnV3Vault mockYearnV3Vault = new MockYearnV3Vault(
            address(mockUSDT)
        );

        uint256 amount = 100;

        mockUSDT.mint(address(msg.sender), amount);

        mockUSDT.approve(address(mockYearnV3Vault), amount);

        mockYearnV3Vault.deposit(amount, address(msg.sender));

        vm.stopBroadcast();
    }
}
