// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {MockUSDT} from "../src/MockUSDT.sol";
import {MockYearnV3Vault} from "../src/MockYearnV3Vault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UniversalComposer} from "../src/UniversalComposer.sol";
import {BaseDeployer} from "./BaseDeployer.s.sol";

contract DeployComposerScript is Script, BaseDeployer {
    function setUp() public {}

    function run() public {
        Chains[] memory deployForks = new Chains[](4);
        deployForks[0] = Chains.Ethereum;
        deployForks[1] = Chains.Polygon;
        deployForks[2] = Chains.Arbitrum;
        deployForks[3] = Chains.Optimism;
        createDeployMultichain(deployForks);
    }

    function chainDeployUniversalComposer(
        address endpoint,
        address stargateOApp
    ) public broadcast(vm.envUint("PRIVATE_KEY")) {
        UniversalComposer universalComposer = new UniversalComposer(
            endpoint,
            stargateOApp
        );

        address owner = universalComposer.owner();
        console.log(owner);
    }

    /// @dev Helper to iterate over chains and select fork.
    /// @param deployForks The chains to deploy to.
    function createDeployMultichain(Chains[] memory deployForks) public {
        for (uint256 i; i < deployForks.length; ) {
            createSelectFork(deployForks[i]);

            Tokens[] memory tokens = supportTokens[deployForks[i]];

            for (uint256 j; j < tokens.length; ) {
                address stargateOApp = stargateOApps[deployForks[i]][tokens[j]];

                chainDeployUniversalComposer(
                    endpoints[deployForks[i]],
                    stargateOApp
                );

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }
}
