import { Address, Chain, encodeFunctionData, erc20Abi } from "viem";
import { optimismSepolia, polygon } from "viem/chains";
import YearnV3Vault from "./abi/YearnV3Vault.json";
import { getOperationCalldata } from "./estimateComposerGas";

type Addresses = {
  chain: Chain;
  composer: Address;
  usdt: Address;
  poolUsdt: Address;
  yearnV3Vault: Address;
  receiver: Address;
};

const predefinedConfigs: Record<string, Record<string, Addresses>> = {
  testnet: {
    optimismSepolia: {
      chain: optimismSepolia,
      composer: "0x15d1d4ba9095379eafd6ec62711c581fd09ba703",
      usdt: "0x9352001271a0af0d09a4e7f6c431663a2d5aa9d2",
      poolUsdt: "0x0d7aB83370b492f2AB096c80111381674456e8d8",
      yearnV3Vault: "0x42c2dfd03934ee63c869a973834b16ce3fb97399",
      receiver: "0x436f795B64E23E6cE7792af4923A68AFD3967952",
    },
  },
  mainnet: {
    polygon: {
      chain: polygon,
      composer: "0x533e75a2879bd2F2eAA8780f8CA1684dbC189362",
      usdt: "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
      poolUsdt: "0xd47b03ee6d86Cf251ee7860FB2ACf9f91B9fD4d7",
      yearnV3Vault: "0xBb287E6017d3DEb0e2E65061e8684eab21060123",
      receiver: "0xbE988fC9F6F8ad1EBb3A58B6c25BD6be9D1F56fe",
    },
  },
};

const composerOptimismSepolia: Address =
  "0x15d1d4ba9095379eafd6ec62711c581fd09ba703";
const usdtOptimismSepolia: Address =
  "0x9352001271a0af0d09a4e7f6c431663a2d5aa9d2";
const yearnV3VaultOptimismSepolia: Address =
  "0x42c2dfd03934ee63c869a973834b16ce3fb97399";

function assertAddress(value: string): asserts value is Address {
  if (!value.startsWith("0x") || value.length !== 42) {
    throw new Error("Invalid Ethereum address format");
  }
}

const main = async (account: Address) => {
  const config = predefinedConfigs.testnet.optimismSepolia;
  const depositAmount = 99n;
  const txs: {
    to: Address;
    value: bigint;
    data: `0x${string}`;
  }[] = [
    {
      to: config.usdt,
      value: 0n,
      data: encodeFunctionData({
        abi: erc20Abi,
        functionName: "approve",
        args: [config.yearnV3Vault, depositAmount],
      }),
    },
    {
      to: config.yearnV3Vault,
      value: 0n,
      data: encodeFunctionData({
        abi: YearnV3Vault,
        functionName: "deposit",
        args: [depositAmount, config.receiver],
      }),
    },
  ];

  // estimateComposerGas(chain, account, composer, txs);
  const callData = await getOperationCalldata(
    config.chain,
    config.composer,
    txs
  );
  console.log(callData);
};

const args = process.argv.slice(2);
if (args.length < 1) {
  console.log("Please provide at least one argument");
  process.exit(1);
}
const account = args[0] as Address;
assertAddress(account);
main(account);
