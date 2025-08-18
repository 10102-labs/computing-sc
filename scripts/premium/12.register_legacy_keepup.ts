
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
    const automation = "0xfc7dc14b8c1416d9a409612732f4131f6007aa15";

    const Automation = JSON.parse(
        fs.readFileSync(
            "./artifacts/contracts/premium/PremiumAutomation.sol/PremiumAutomation.json",
            "utf-8"
        )
    ).abi;


    const txCount = await web3.eth.getTransactionCount(user);

        const contract = new web3.eth.Contract(Automation, automation);

        const txData = contract.methods
            .registerKeepupLegacy(["0xa1622A2f5151555b34E5d2Ee504025d5fA664587"])
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


}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
