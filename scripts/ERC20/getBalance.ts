import * as dotenv from "dotenv";
dotenv.config();

import { ethers } from "ethers";
import * as fs from "fs";
import { getProvider } from "../utils";

const erc20s = ["0xec82a12F02035bf5689BCd16DE8C6a8F337F558B"];
const multicallAddr = "0x25eef291876194aefad0d60dff89e268b90754bb";
const user = "0x3e7B97355f0C8518136A62298d68C1CdDc3ed68d";

const ERC20_ABI = ["function balanceOf(address account) view returns (uint256)"];

const MULTICALL3_ABI = ["function aggregate(tuple(address target, bytes callData)[] calls) public returns (uint256 blockNumber, bytes[] returnData)"];

async function main() {
  const { provider } = getProvider();
  const multicall = new ethers.Contract(multicallAddr, MULTICALL3_ABI, provider);

  const iface = new ethers.utils.Interface(ERC20_ABI);
  const calls = erc20s.map((tokenAddr) => ({
    target: tokenAddr,
    callData: iface.encodeFunctionData("balanceOf", [user]),
  }));

  const [, returnData] = await multicall.callStatic.aggregate(calls);

  const balances = returnData.map((data: any, i: any) => ethers.BigNumber.from(data).toString());

  console.log(balances);
}

main();
