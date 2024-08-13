// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";

/* solhint-disable max-states-count */
contract BaseDeployer is Script {
    uint256 internal deployerPrivateKey;

    enum Chains {
        Ethereum,
        Polygon,
        Arbitrum,
        Optimism
    }

    enum Tokens {
        Native,
        USDT,
        USDC
    }

    /// @dev Mapping of chain enum to rpc url
    mapping(Chains chains => string rpcUrls) public forks;

    /// @dev Mapping of chain enum to stargateOApp
    mapping(Chains chains => Tokens[] tokens) public supportTokens;

    /// @dev Mapping of chain enum to layer zero endpoint address
    mapping(Chains chains => address layerzeroEndpoint) public endpoints;

    /// @dev Mapping of chain enum to stargateOApp
    mapping(Chains chains => mapping(Tokens tokens => address tokenAddress))
        public stargateOApps;

    /// @dev broadcast transaction modifier
    /// @param pk private key to broadcast transaction
    modifier broadcast(uint256 pk) {
        vm.startBroadcast(pk);

        _;

        vm.stopBroadcast();
    }

    constructor() {
        // Mainnet
        forks[Chains.Ethereum] = "mainnet";
        forks[Chains.Polygon] = "polygon";
        forks[Chains.Arbitrum] = "arbitrum";
        forks[Chains.Optimism] = "optimism";

        supportTokens[Chains.Ethereum] = [
            Tokens.Native,
            Tokens.USDT,
            Tokens.USDC
        ];
        supportTokens[Chains.Polygon] = [
            Tokens.USDT,
            Tokens.USDC
        ];
        supportTokens[Chains.Arbitrum] = [
            Tokens.Native,
            Tokens.USDT,
            Tokens.USDC
        ];
        supportTokens[Chains.Optimism] = [
            Tokens.Native,
            Tokens.USDT,
            Tokens.USDC
        ];

        endpoints[Chains.Ethereum] = address(
            0x1a44076050125825900e736c501f859c50fE728c
        );
        endpoints[Chains.Polygon] = address(
            0x1a44076050125825900e736c501f859c50fE728c
        );
        endpoints[Chains.Arbitrum] = address(
            0x1a44076050125825900e736c501f859c50fE728c
        );
        endpoints[Chains.Optimism] = address(
            0x1a44076050125825900e736c501f859c50fE728c
        );

        stargateOApps[Chains.Ethereum][Tokens.Native] = address(
            0x77b2043768d28E9C9aB44E1aBfC95944bcE57931
        );
        stargateOApps[Chains.Ethereum][Tokens.USDT] = address(
            0x933597a323Eb81cAe705C5bC29985172fd5A3973
        );
        stargateOApps[Chains.Ethereum][Tokens.USDC] = address(
            0xc026395860Db2d07ee33e05fE50ed7bD583189C7
        );

        stargateOApps[Chains.Polygon][Tokens.USDT] = address(
            0xd47b03ee6d86Cf251ee7860FB2ACf9f91B9fD4d7
        );
        stargateOApps[Chains.Polygon][Tokens.USDC] = address(
            0x9Aa02D4Fae7F58b8E8f34c66E756cC734DAc7fe4
        );

        stargateOApps[Chains.Arbitrum][Tokens.Native] = address(
            0xA45B5130f36CDcA45667738e2a258AB09f4A5f7F
        );
        stargateOApps[Chains.Arbitrum][Tokens.USDT] = address(
            0xcE8CcA271Ebc0533920C83d39F417ED6A0abB7D0
        );
        stargateOApps[Chains.Arbitrum][Tokens.USDC] = address(
            0xe8CDF27AcD73a434D661C84887215F7598e7d0d3
        );

        stargateOApps[Chains.Optimism][Tokens.Native] = address(
            0xe8CDF27AcD73a434D661C84887215F7598e7d0d3
        );
        stargateOApps[Chains.Optimism][Tokens.USDT] = address(
            0x19cFCE47eD54a88614648DC3f19A5980097007dD
        );
        stargateOApps[Chains.Optimism][Tokens.USDC] = address(
            0xcE8CcA271Ebc0533920C83d39F417ED6A0abB7D0
        );
    }

    function createFork(Chains chain) public {
        vm.createFork(forks[chain]);
    }

    function createSelectFork(Chains chain) public {
        vm.createSelectFork(vm.rpcUrl(forks[chain]));
    }
}
