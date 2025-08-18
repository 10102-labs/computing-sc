import * as dotenv from "dotenv";
import { ethers } from "ethers";

import Web3 from "web3";

const web3 = new Web3(process.env.RPC!);

dotenv.config();

import * as fs from "fs";
import { getProvider } from "../utils";

async function main() {
  const timelock = "0xf4aB0cb57cE9621a7d798A7071DAEBab385E8f0D";

  const timelockRouter = JSON.parse(fs.readFileSync("./artifacts/contracts/timelock/TimeLockRouter.sol/TimeLockRouter.json", "utf-8")).abi;

  const { provider, wallet } = getProvider();
  const timelockRouterIns = new ethers.Contract(timelock, timelockRouter, wallet);

  const data = await timelockRouterIns.createTimelockWithSafe(
    {
      timelockERC20: [
        {
          tokenAddress: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
          amount: "1000000000000",
        },
      ],
      timelockERC721: [],
      timelockERC1155: [],
      duration: "86400",
      name: "TestName",
    },
    "0x82B4d7A5DC90E2d505faCBFa01ef259D60621cca"
  );

  console.log(`Create timelock at tx ${data.hash}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


