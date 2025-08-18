import Web3 from "web3";
import { ethers } from "ethers";
import * as dotenv from "dotenv";
dotenv.config();

import * as fs from "fs";
import { saveContract, getContracts, sleep } from "../utils";

const web3 = new Web3(process.env.RPC!);

const user_pk = process.env.PK;

const user = web3.eth.accounts.privateKeyToAccount(user_pk!).address;

enum Plan {
    ONE_YEAR,
    FIVE_YEARS,
    LIFETIME
}
const ONE_YEAR_PRICE = 1000;
const FIVE_YEARS_PRICE = 2500;
const LIFETIME_PRICE = 5000;
const setting = "0x283720b2102d97992Adc3E695A4d5a3690A95561"
const registry = "0x5466621cb4ac2f6e4aE3930026576647158E49dD";
const verifier = "0xFA7B36E80299131d5069D384699cfC887Fe09233";
const multisigLegacyRouter = "0x379d729b5e1305a7b5d57DE2908A2DB80028DD1A";
const transferLegacyRouter = "0x66E4912a7066D5850e07cA761d444124309fc067";
const transferEOALegacyRouter = "0xb12b4A1bbe14b6Fe0b7D2cBD5B56DC09e7cc3a5d";


// notification
const enpsComm = "0x0C34d54a09CFe75BCcd878A469206Ae77E0fe6e7";
const channel = "0x944A402a91c3D6663f5520bFe23c1c1eE77BCa92";
const mananger = "0xB8FCc4eB187816014293387483AfeeE96d835CEF";
const notification = "0xFc6e9b9734F7e1e96C126b1a9B58c29a7A1DC774";




const Registry = JSON.parse(
    fs.readFileSync(
        "./artifacts/contracts/premium/PremiumRegistry.sol/PremiumRegistry.json",
        "utf-8"
    )
).abi;

const Setting = JSON.parse(
    fs.readFileSync(
        "./artifacts/contracts/premium/PremiumSetting.sol/PremiumSetting.json",
        "utf-8"
    )
).abi;

const EIP712LegacyVerifier = JSON.parse(
    fs.readFileSync(
        "./artifacts/contracts/term/VerifierTerm.sol/EIP712LegacyVerifier.json",
        "utf-8"
    )
).abi;

const PremiumNotification = JSON.parse(
    fs.readFileSync(
        "./artifacts/contracts/premium/PremiumNotification.sol/PremiumNotification.json",
        "utf-8"
    )
).abi;

async function setPlanPrice() {
    console.log('Setting Plan prices...');

    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(Registry);

    const txData = contract.methods
        .setPlanPrices(
            [Plan.ONE_YEAR, Plan.FIVE_YEARS, Plan.LIFETIME],
            [ONE_YEAR_PRICE , FIVE_YEARS_PRICE , LIFETIME_PRICE ]
        ).encodeABI();

    //using ETH
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(1000000),
        gasPrice: await web3.eth.getGasPrice(),
        data: txData,
        to: registry,
        from: user,
    };

    const signedTx = await web3.eth.accounts.signTransaction(txObj, user_pk!);

    const result = await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
    console.log(result);
}

async function setPramramPremiumSetting() {

    console.log('setPramramPremiumSetting...');
    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(Setting);

    const txData = contract.methods
        .setParams(registry, transferLegacyRouter, transferEOALegacyRouter, multisigLegacyRouter, mananger ).encodeABI();

    //using ETH
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(1000000),
        gasPrice: await web3.eth.getGasPrice(),
        data: txData,
        to: setting,
        from: user,
    };

    const signedTx = await web3.eth.accounts.signTransaction(txObj, user_pk!);

    const result = await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
    console.log(result);
}


async function init() {

    console.log('Setting PremiumRegistry...');
    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(Setting);

    const txData = contract.methods
        .initialize().encodeABI();

    //using ETH
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(1000000),
        gasPrice: await web3.eth.getGasPrice(),
        data: txData,
        to: setting,
        from: user,
    };

    const signedTx = await web3.eth.accounts.signTransaction(txObj, user_pk!);

    const result = await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
    console.log(result);
}

async function setRouterAddresses() {
    console.log('Setting Router...');
    const txCount = await web3.eth.getTransactionCount(user);
    const contract = new web3.eth.Contract(EIP712LegacyVerifier, verifier);

    const txData = contract.methods
    .setRouterAddresses(transferEOALegacyRouter, transferLegacyRouter, multisigLegacyRouter).encodeABI();

    //using ETH
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(1000000),
        gasPrice: await web3.eth.getGasPrice(),
        data: txData,
        to: verifier,
        from: user,
    };

    const signedTx = await web3.eth.accounts.signTransaction(txObj, user_pk!);

    const result = await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
    console.log(result);


}

async function main() {
    // await setPlanPrice();
    // await setPremiumRegistry();
    //init();
    await setPramramPremiumSetting();
    // await setRouterAddresses();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
