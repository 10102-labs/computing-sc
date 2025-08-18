import * as dotenv from "dotenv";
dotenv.config();

import { ethers } from "ethers";
import * as fs from "fs";
import { getProvider } from "../utils";

const usdt = "0x02f62735EaF5fFB56B629bC529e72801713f27cd"
const usdc = "0xC1Fa197B73577868516dDA2492d44568D9Ec884c";
const erc20 = usdt;
const spender = "0xcdfca2a01cabefa3fe3745a6d82e136ca669abd7";

const ERC20ABI = JSON.parse(fs.readFileSync("./artifacts/contracts/mock/ERC20Token.sol/ERC20Token.json", "utf-8")).abi;

async function main() {
  // const contractRunner = await ethers.getSigner(deployer);

  const { provider, wallet } = getProvider();
  const erc20Ins = new ethers.Contract(erc20, ERC20ABI, wallet);

  const data = await erc20Ins.approve(spender, "1000000000");
  console.log(`Approve token ${erc20} to contract ${spender} at tx ${data.hash}`);
}
main();
