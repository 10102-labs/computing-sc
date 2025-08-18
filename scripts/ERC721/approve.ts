import Web3 from "web3";
import { ethers } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

import * as fs from "fs";
import { parseEther } from "ethers/lib/utils";
import { getProvider } from "../utils";

const web3 = new Web3(process.env.RPC!);
const user_pk = process.env.PK;

const user = web3.eth.accounts.privateKeyToAccount(user_pk!).address;

async function main() {
  const token = "0x02f62735EaF5fFB56B629bC529e72801713f27cd";
  const operator = "0x43a04683dF16C222C57E8f206ad1c694762C1158";

  const ERC721ABI = JSON.parse(fs.readFileSync("./artifacts/contracts/mock/ERC721Token.sol/MockERC721.json", "utf-8")).abi;

  // const contractRunner = await ethers.getSigner(deployer);

  const { provider, wallet } = getProvider();
  const erc721Ins = new ethers.Contract(token, ERC721ABI, wallet);

  const data = await erc721Ins.setApprovalForAll(operator, true);
  console.log(`Approve token ${token} to contract ${operator} at tx ${data.hash}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
