import Web3 from "web3";
import { ethers } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

import * as fs from "fs";
import { parseEther } from "ethers/lib/utils";
import { getProvider } from "../utils";
import { ERC1155, ERC1155__factory } from "../../typechain-types";

async function main() {
  const token = "0x02f62735EaF5fFB56B629bC529e72801713f27cd";
  const operator = "0x43a04683dF16C222C57E8f206ad1c694762C1158";

  const ERC1155 = JSON.parse(fs.readFileSync("./artifacts/contracts/mock/ERC1155Token.sol/MockERC1155.json", "utf-8")).abi;

  const { provider, wallet } = getProvider();
  const erc1155Ins = new ethers.Contract(token, ERC1155, wallet);

  const data = await erc1155Ins.setApprovalForAll(operator, true);
  console.log(`Approve token ${token} to contract ${operator} at tx ${data.hash}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
