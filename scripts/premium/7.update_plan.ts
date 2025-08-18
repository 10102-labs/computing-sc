
import Web3 from "web3";
import { ethers } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

import * as fs from "fs";


const web3 = new Web3(process.env.RPC!);
const user_pk = process.env.PK;

const OPERATOR = "0x523a704056dcd17bcf83bed8b68c59416dac1119be77755efe3bde0a64e46e0c";
const user = web3.eth.accounts.privateKeyToAccount(user_pk!).address;

const ONE_YEAR_PRICE = 1000;
const FIVE_YEARS_PRICE = 2500;
const LIFETIME_PRICE = 5000;

const ONE_YEAR = 86400 * 365;
const FIVE_YEARS = 86400 * 365 * 5;
const LIFETIME = ethers.constants.MaxUint256;


async function main() {
    const registry = "0x5466621cb4ac2f6e4aE3930026576647158E49dD";
    const Registry = JSON.parse(
        fs.readFileSync(
            "./artifacts/contracts/premium/PremiumRegistry.sol/PremiumRegistry.json",
            "utf-8"
        )
    ).abi;

    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(Registry, registry);

    const txData = await contract.methods
        .updatePlans(
            [12],
            [600],
            [100],
            ["10 Mins"],
            [
            "10 Mins"
            ],
            ["10 Mins"],

        )
        .encodeABI();
    console.log(txData);

    //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()

    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(1000000),
        gasPrice: await web3.eth.getGasPrice(),
        // maxPriorityFeePerGas:web3.utils.toHex (100),

        data: txData,
        to: registry,
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
