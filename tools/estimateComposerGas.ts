import {
  Address,
  Chain,
  createPublicClient,
  encodeFunctionData,
  getContract,
  http,
  TransactionRequestBase,
} from "viem";
import UniversalComposer from "./abi/UniversalComposer.json";

const composerOptimismSepolia: Address =
  "0x15d1d4ba9095379eafd6ec62711c581fd09ba703";
const StargatePoolUSDCOptimismSepolia: Address =
  "0x0d7aB83370b492f2AB096c80111381674456e8d8";

const layerZeroOptimismSepoliaEndpoint: Address =
  "0x6EDCE65403992e310A62460808c4b910D972f10f";

type Operation = {
  to: Address;
  value: bigint;
  data: string;
};

export const getOperationCalldata = async (
  chain: Chain,
  composer: Address,
  txs: {
    to: Address;
    value: bigint;
    data: `0x${string}`;
  }[]
) => {
  const publicClient = createPublicClient({
    chain: chain,
    transport: http(),
  });

  const contract = getContract({
    address: composer,
    abi: UniversalComposer,
    client: publicClient,
  });

  const operations = txs.map(transformer);

  const operationCalldata = await contract.read.encodeOperation([operations]);
  return operationCalldata;
};

// TODO: Implement this function
export const estimateComposerGas = async (
  chain: Chain,
  account: Address,
  composer: Address,
  txs: {
    to: Address;
    value: bigint;
    data: `0x${string}`;
  }[]
) => {
  const publicClient = createPublicClient({
    chain: chain,
    transport: http(),
  });

  const operationCalldata = await getOperationCalldata(chain, composer, txs);

  console.log(`typeof operationCallData: `, typeof operationCalldata);
  console.log(`operationCallData: `, operationCalldata);

  // address _from,
  // address _to,
  // bytes32 _guid,
  // uint16 _index,
  // bytes calldata _message,
  // bytes calldata _extraData

  const calldata = encodeFunctionData({
    abi: UniversalComposer,
    functionName: "lzCompose",
    args: [StargatePoolUSDCOptimismSepolia, composerOptimismSepolia],
  });

  const gas = await publicClient.estimateGas({
    account,
    to: layerZeroOptimismSepoliaEndpoint,
    value: 0n,
    data: calldata,
  });
  console.log(`Estimated gas: ${gas}`);
  return gas;
};

const transformer = (tx: Omit<TransactionRequestBase, "from">): Operation => {
  if (!tx.to) throw new Error("Invalid transaction");
  return {
    to: tx.to,
    value: tx.value || 0n,
    data: tx.data || "",
  };
};
