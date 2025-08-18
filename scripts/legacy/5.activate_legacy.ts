
import Web3 from "web3";
import { ethers } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

import * as fs from "fs";
import { parseEther } from "ethers/lib/utils";


const web3 = new Web3(process.env.RPC!);
const user_pk = process.env.PK;

const user = web3.eth.accounts.privateKeyToAccount(user_pk!).address;

const legacyId =111 ;
const routerTransferEOA = "0xb12b4A1bbe14b6Fe0b7D2cBD5B56DC09e7cc3a5d";
const routerTransferSafe = "0x66E4912a7066D5850e07cA761d444124309fc067"; 
const usdt = "0x02f62735EaF5fFB56B629bC529e72801713f27cd"
const usdc = "0xC1Fa197B73577868516dDA2492d44568D9Ec884c";
async function main() {
    const legacyRouter = routerTransferEOA;

    const LegacyRouter = JSON.parse(
        fs.readFileSync(
            "./artifacts/contracts/forwarding/TransferLegacyEOAContractRouter.sol/TransferEOALegacyRouter.json",
            "utf-8"
        )
    ).abi;

    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(LegacyRouter, legacyRouter);

    const txData = contract.methods
        . activeLegacy(legacyId, [usdt, usdc], true)
        .encodeABI();
    console.log(txData);

    //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(10000000),
        gasPrice: (await web3.eth.getGasPrice()).toString(),
        data: txData,
        to:  legacyRouter,
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
