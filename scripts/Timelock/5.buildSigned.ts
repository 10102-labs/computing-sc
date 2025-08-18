import { ethers, Signer } from "ethers";
import { timelock } from "../../typechain-types/contracts";

import dotenv from "dotenv";
import { getProvider } from "../utils";

import * as fs from "fs";

dotenv.config();

export const EIP712_SAFE_TX_TYPE = {
  // "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
  SafeTx: [
    { type: "address", name: "to" },
    { type: "uint256", name: "value" },
    { type: "bytes", name: "data" },
    { type: "uint8", name: "operation" },
    { type: "uint256", name: "safeTxGas" },
    { type: "uint256", name: "baseGas" },
    { type: "uint256", name: "gasPrice" },
    { type: "address", name: "gasToken" },
    { type: "address", name: "refundReceiver" },
    { type: "uint256", name: "nonce" },
  ],
};
export const buildMetaTransaction = async (
  signer: Signer,
  contractAddress: string,
  to: string,
  value: string,
  data: string,
  nonce: string,
  operation: string
) => {
  const cid = signer.provider && (await signer.provider.getNetwork()).chainId;

  return await (signer as any)._signTypedData(
    // domain
    {
      verifyingContract: contractAddress,
      chainId: cid,
    },
    EIP712_SAFE_TX_TYPE,
    {
      to,
      value,
      data,
      operation,
      gasToken: "0x0000000000000000000000000000000000000000",
      safeTxGas: 0,
      baseGas: 0,
      gasPrice: 0,
      refundReceiver: "0x0000000000000000000000000000000000000000",
      nonce,
    }
  );
};

async function main() {
  const { provider } = getProvider();

  const signature = await buildMetaTransaction(
    new ethers.Wallet(process.env.PK as string, provider),
    "0x82B4d7A5DC90E2d505faCBFa01ef259D60621cca",
    "0xf4aB0cb57cE9621a7d798A7071DAEBab385E8f0D",
    "0",
    "0xa4c717c30000000000000000000000000000000000000000000000000000000000000002",
    "1",
    "0"
  );

  console.log(signature);
}

async function execSafe() {
  const { provider, wallet } = getProvider();

  const safe = "0x82B4d7A5DC90E2d505faCBFa01ef259D60621cca";

  const Safe_ABI = JSON.parse(fs.readFileSync("./scripts/Timelock/Safe.json", "utf-8")).abi;

  const safeIns = new ethers.Contract(safe, Safe_ABI, wallet);

  const tx = await safeIns.execTransaction(
    "0xf4aB0cb57cE9621a7d798A7071DAEBab385E8f0D", // to contract
    "0",
    "0xa4c717c30000000000000000000000000000000000000000000000000000000000000002", // data
    "0",
    "0",
    "0",
    "0",
    "0x0000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000",
    "0x3444b7642f2466be3803fee35659abff524f9ab753651b27f998a2e0ced6b78951bdf52030358f73346db1ed4fcd6884c66faa262c62a1bda47926b92428af221c"
  );

  console.log(tx);
}

execSafe();
