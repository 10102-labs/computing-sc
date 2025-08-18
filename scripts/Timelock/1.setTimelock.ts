import * as dotenv from "dotenv";
import { ethers } from "ethers";

dotenv.config();

import * as fs from "fs";
import { getProvider } from "../utils";

async function main() {
  const timelock = "0xf4aB0cb57cE9621a7d798A7071DAEBab385E8f0D";
  const timelockERC20 = "0x573128C00d0cFBc6929EDF09064A5636665C2254";
  const timelockERC721 = "0xfe42aDab144530e025bbCBF76C5Bf1c643407b71";
  const timelockERC1155 = "0x2fbC9C312EA201d820201Ab664E61Dd497DFBef5";

  const timelockRouter = JSON.parse(fs.readFileSync("./artifacts/contracts/timelock/TimeLockRouter.sol/TimeLockRouter.json", "utf-8")).abi;

  const { provider, wallet } = getProvider();
  const timelockRouterIns = new ethers.Contract(timelock, timelockRouter, wallet);

  const data = await timelockRouterIns.setTimelock(timelockERC20, timelockERC721, timelockERC1155);

  console.log(`Set timelock at tx ${data.hash}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
