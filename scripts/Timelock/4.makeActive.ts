import * as dotenv from "dotenv";
import { ethers } from "ethers";

import Web3 from "web3";

const web3 = new Web3(process.env.RPC!);

dotenv.config();

import * as fs from "fs";
import { getProvider } from "../utils";

async function main() {
  const Safe_ABI = ["function enableModule(address module) public"];
  const safeAddress = "0x82B4d7A5DC90E2d505faCBFa01ef259D60621cca";

  const Timelock_ABI = ["function makeLiveBySafe(uint256 id) public"];
  const timelock = "0xf4aB0cb57cE9621a7d798A7071DAEBab385E8f0D";

  const { provider, wallet } = getProvider();

  const ifaceSafe = new ethers.utils.Interface(Safe_ABI);
  const callSafe = [
    {
      target: safeAddress,
      callData: ifaceSafe.encodeFunctionData("enableModule", [timelock]),
    },
  ];

  const ifaceTimelock = new ethers.utils.Interface(Timelock_ABI);
  const callTimelock = [
    {
      target: timelock,
      callData: ifaceTimelock.encodeFunctionData("makeLiveBySafe", [2]),
    },
  ];

  console.log({ callSafe, callTimelock });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
