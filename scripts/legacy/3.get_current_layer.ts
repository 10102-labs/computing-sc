
import Web3 from "web3";
import { ethers } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

import * as fs from "fs";
import { parseEther } from "ethers/lib/utils";


const web3 = new Web3(process.env.RPC!);
const user_pk = process.env.PK;

const user = web3.eth.accounts.privateKeyToAccount(user_pk!).address;

async function main() {
    const legacy = "0xf3b31ee9624F3C5AdD0BECA2A0a19774Ab94Cb61";

    const Legacy = JSON.parse(
        fs.readFileSync(
            "./artifacts/contracts/forwarding/TransferLegacyEOAContract.sol/TransferEOALegacy.json",
            "utf-8"
        )
    ).abi;

    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(Legacy, legacy);

    const txData = contract.methods
        .getCurrentLayer()
        .call();
      console.log(txData);
   

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
