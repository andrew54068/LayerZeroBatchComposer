# Universal Composer
A LayerZero Composer served as a starting point of arbitrary tx operation after bridged token from another blockchain using stargate.

for more info, please refer to [Stargate Composability](https://stargateprotocol.gitbook.io/stargate/v/v2-developer-docs/integrate-with-stargate/composability)

## Contracts

### Testnet

#### Optimism Sepolia
[UniversalComposer](https://sepolia-optimism.etherscan.io/address/0x15d1d4ba9095379eafd6ec62711c581fd09ba703#code)

[MockedYearnV3](https://sepolia-optimism.etherscan.io/address/0x42c2dfd03934ee63c869a973834b16ce3fb97399#code)

### Mainnet

### Polygon
[UniversalComposer](https://polygonscan.com/address/0x533e75a2879bd2F2eAA8780f8CA1684dbC189362#code)


## Usage

### Build

```shell
$ forge build
```

### Run Scripts

### Testnet
Stargate does not support amoy testnet yet, so we use **Arbitrum Sepolia -> Optimism Sepolia** instead.

#### 1.) Make sure to fill the PRIVATE_KEY to .env file 

#### 2.) Deploy Composer to destination chain and verify contract
```shell
source .env

forge create src/UniversalComposer.sol:UniversalComposer \
--rpc-url optimismSepolia \
--constructor-args 0x6EDCE65403992e310A62460808c4b910D972f10f 0x0d7aB83370b492f2AB096c80111381674456e8d8 \
--private-key $PRIVATE_KEY \
--etherscan-api-key $OP_ETHERSCAN_API_KEY \
--verify
```
or

Fill in your sender to the script below
```shell
forge script ./script/DeployComposerScript.s.sol:DeployComposerScript \
--via-ir \
-vvvv \
--broadcast \
--rpc-url optimismSepolia \
--sender 0x436f795B64E23E6cE7792af4923A68AFD3967952

source .env

forge verify-contract \
0x0310B6291086981C5773434684c3D3dD12D6d57e \
--chain optimism-sepolia \
--verifier-url $OPTIMISM_SEPOLIA_ETHERSCAN_API \
src/UniversalComposer.sol:UniversalComposer \
--constructor-args $(cast abi-encode "constructor(address,address)" 0x6EDCE65403992e310A62460808c4b910D972f10f 0x0d7aB83370b492f2AB096c80111381674456e8d8) \
--etherscan-api-key $OP_ETHERSCAN_API_KEY
```

#### 3.) Send token with message from Arbitum Sepolia
```shell
forge script ./script/BridgeTestnetTokenScript.s.sol:BridgeTestnetTokenScript \
--via-ir \
-vvvv \
--rpc-url arbitrumSepolia \
--sender 0x436f795B64E23E6cE7792af4923A68AFD3967952 \
--sig "run(address,uint128,string)" -- 0x15d1d4ba9095379eafd6ec62711c581fd09ba703 32000 "9352001271a0af0d09a4e7f6c431663a2d5aa9d200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b300000000000000000000000042c2dfd03934ee63c869a973834b16ce3fb97399000000000000000000000000000000000000000000000000000000000000006342c2dfd03934ee63c869a973834b16ce3fb97399000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000446e553f650000000000000000000000000000000000000000000000000000000000000063000000000000000000000000436f795b64e23e6ce7792af4923a68afd3967952" \
--broadcast
```

#### Addition
 Deploy Mocked YearnV3 vault and verify contract
```shell
forge create src/MockYearnV3Vault.sol:MockYearnV3Vault \
--rpc-url optimismSepolia \
--constructor-args 0x9352001271a0af0d09a4e7F6C431663A2D5AA9d2 \
--private-key $PRIVATE_KEY \
--etherscan-api-key $OP_ETHERSCAN_API_KEY \
--verify
```

### Mainnet
#### 1.) Make sure to fill the PRIVATE_KEY to .env file 

#### 2.) Deploy Composer to destination chain and verify contract
```shell
source .env

forge create src/UniversalComposer.sol:UniversalComposer \
--rpc-url polygon \
--constructor-args 0x1a44076050125825900e736c501f859c50fE728c 0xd47b03ee6d86Cf251ee7860FB2ACf9f91B9fD4d7 \
--private-key $PRIVATE_KEY \
--etherscan-api-key $POLYGONSCAN_API_KEY \
--verify
```
#### 3.) Send token with message from Arbitum -> Polygon
```shell
forge script ./script/BridgeMainnetTokenScript.s.sol:BridgeMainnetTokenScript \
--via-ir \
--rpc-url arbitrum \
-vvvv \
--broadcast \
--sender 0x436f795B64E23E6cE7792af4923A68AFD3967952 \
--sig "run(address,uint128,string)" -- 0x533e75a2879bd2F2eAA8780f8CA1684dbC189362 500000 "c2132d05d31c914a87c6611c10748aeb04b58e8f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b3000000000000000000000000bb287e6017d3deb0e2e65061e8684eab210601230000000000000000000000000000000000000000000000000000000000000063bb287e6017d3deb0e2e65061e8684eab21060123000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000446e553f650000000000000000000000000000000000000000000000000000000000000063000000000000000000000000be988fc9f6f8ad1ebb3a58b6c25bd6be9d1f56fe"
```
[LayerZero Scan](https://layerzeroscan.com/tx/0xb1146126110a3cd48e1658507e448aad90b9de554a48c3a73868d076e24e447b)\
[Success Composer Tx](https://polygonscan.com/tx/0xd314d719e4b4e6b3b514ea3e3c7abd048ef1e7e47895abc670277c86ef9db928)

### Test

```shell
$ forge test
```
