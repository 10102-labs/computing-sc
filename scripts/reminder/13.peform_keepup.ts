
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
    const automation = "0xEecBF1EA0cb9D937Cbbc17C8f62E43D3C8Bc3a25";


    const Automation = JSON.parse(
        fs.readFileSync(
            "./artifacts/contracts/premium/PremiumAutomation.sol/PremiumAutomation.json",
            "utf-8"
        )
    ).abi;


    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(Automation, automation);

    const checkUpkeepData = await contract.methods
        .checkUpkeep("0x")
        .call();
    console.log(checkUpkeepData);
    if (checkUpkeepData && checkUpkeepData[1] != '0x') {

        const txData = contract.methods
            .performUpkeep(checkUpkeepData[1])
            .encodeABI();
        console.log(txData);

        //using ETH
        const calculateFeeData = await web3.eth.calculateFeeData()
        const txObj = {
            nonce: txCount,
            gas: web3.utils.toHex(2000000),
            gasPrice: (await web3.eth.getGasPrice()).toString(),
            data: txData,
            to: automation,
            from: user,

        };

        const signedTx = await web3.eth.accounts.signTransaction(txObj, user_pk!);

        const result = await web3.eth.sendSignedTransaction(
            signedTx.rawTransaction!
        );
        console.log(result);
    } else {
        console.log("Not keep up");
    }


}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
