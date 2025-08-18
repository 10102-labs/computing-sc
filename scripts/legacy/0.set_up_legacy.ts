import Web3 from "web3";
import { ethers } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

import * as fs from "fs";
import { parseEther } from "ethers/lib/utils";


const web3 = new Web3(process.env.RPC!);
const user_pk = process.env.PK;

const user = web3.eth.accounts.privateKeyToAccount(user_pk!).address;
const wallet = web3.eth.accounts.privateKeyToAccount(user_pk!);

async function genMessage(

    legacyAddress: string,
    timestamp: bigint): Promise<string> {

    const message = `I agree to legacy at address ${legacyAddress.toLowerCase()} at timestamp ${timestamp}`;
    return message;
}

const setting = "0x283720b2102d97992Adc3E695A4d5a3690A95561";
const verifier = "0xFA7B36E80299131d5069D384699cfC887Fe09233";
const payment = "0x8B8F5248f7a0662bc17a785097BaFe0B3A850945";

const router = "0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008";
const weth = "0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9";

const legacyRouter = "0x66E4912a7066D5850e07cA761d444124309fc067";

const LegacyRouter = JSON.parse(
    fs.readFileSync(
        "./artifacts/contracts/forwarding/TransferLegacyEOAContractRouter.sol/TransferEOALegacyRouter.json",
        "utf-8"
    )
).abi;


async function main() {
   
    console.log(user);

    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(LegacyRouter, legacyRouter);


    const txData = contract.methods.setSwapSettings(router, weth).encodeABI();
    console.log(txData);

    //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(5000000),
        gasPrice: (await web3.eth.getGasPrice()).toString(),
        data: txData,
        to: legacyRouter,
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