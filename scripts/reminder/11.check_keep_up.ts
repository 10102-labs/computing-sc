
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
    const automation = "0x0ebF1E4c750f50E96278fc4Ec095a0048fFb9619";

    const Automation = JSON.parse(
        fs.readFileSync(
            "./artifacts/contracts/premium/PremiumAutomation.sol/PremiumAutomation.json",
            "utf-8"
        )
    ).abi;


    const contract = new web3.eth.Contract(Automation, automation);

    const checkUpkeepData = await  contract.methods
        .checkUpkeep("0x")
        .call();
      console.log(checkUpkeepData);

    if (checkUpkeepData && checkUpkeepData[1] != '0x') {
        const txData = await contract.methods
            .decodePerformData(checkUpkeepData[1])
            .encodeABI();
        console.log(txData);

    }

    
    

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
