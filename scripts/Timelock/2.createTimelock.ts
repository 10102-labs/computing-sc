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

  //   const contract = new web3.eth.Contract(timelockRouter, timelock);

  //   const txData = contract.methods
  //     .createTimelock({
  //       timelockERC20: [
  //         {
  //           tokenAddress: "0xec82a12F02035bf5689BCd16DE8C6a8F337F558B",
  //           amount: "1000000000",
  //         },
  //       ],
  //       timelockERC721: [],
  //       timelockERC1155: [],
  //       duration: "86400",
  //       name: "TestName",
  //     })
  //     .encodeABI();

  //   console.log(txData);
  const data = await timelockRouterIns.createTimelock(
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
    {
      value: "1000000",
    }
  );

  console.log(`Create timelock at tx ${data.hash}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
[["0xec82a12F02035bf5689BCd16DE8C6a8F337F558B", "1000000000000000"], [], [], "86400", "TestName"];
