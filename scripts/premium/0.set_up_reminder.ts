
import Web3 from "web3";
import { ethers } from "ethers";
import * as dotenv from "dotenv";
dotenv.config();

import * as fs from "fs";
import { saveContract, getContracts, sleep } from "../utils";
import { error } from "console";



//Premium
const premiumSetting = "0x283720b2102d97992Adc3E695A4d5a3690A95561";
const registry = "0x5466621cb4ac2f6e4aE3930026576647158E49dD";
const verifier = "0xFA7B36E80299131d5069D384699cfC887Fe09233";
const multisigLegacyRouter = "0x379d729b5e1305a7b5d57DE2908A2DB80028DD1A";
const transferLegacyRouter = "0x66E4912a7066D5850e07cA761d444124309fc067";
const transferEOALegacyRouter = "0xb12b4A1bbe14b6Fe0b7D2cBD5B56DC09e7cc3a5d";

//Reminder
const manager = "0x674552d6a2E3F47DfacF362c874eeBa933c82561";
const notification = "0x02f486A3b571d938C51FC24f7a0B6251285b5032"
// const sendMail = "0x5509E8ecfe3E53E4837AFC0B8D9FD719DE7EFDD6";
const sendMailRouter = "0x01e8FBE1Bc34D73d86A61EbC24A0e9509C0B8799";
const mailBeforeActivation = "0x5C49EC40F5a512e2c4181bE1064CaCD55a930f16";
const mailActivated = "0x05C807580CC173D2960304e870f4326a10E9A22C";
const mailReadyToActivate = "0xDf105CA77a010860bf08fE52E454A2D5755354c6";


//CHAINLINK AUTOMATION
const i_link = "0x779877A7B0D9E8603169DdbD7836e478b4624789"; //Token LINK 
const i_registrar = "0xb0E49c5D0d05cbc241d68c05BC5BA1d1B7B72976";
const keeperRegistry = "0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad";
const baseGasLimit = "1500000";

//PUSH
const enpsComm = "0x0C34d54a09CFe75BCcd878A469206Ae77E0fe6e7";
const channel = "0x944a402a91c3d6663f5520bfe23c1c1ee77bca92";

//CHAINLINK FUNCTION
const router =  "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0"; //fix for sepolia
const subcriptionId = 5168;
const donID = "0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000" // fix for sepolia
const gasLimit = "300000";

const web3 = new Web3(process.env.RPC!);

const user_pk = process.env.PK;

const user = web3.eth.accounts.privateKeyToAccount(user_pk!).address;

const Manager = JSON.parse(
    fs.readFileSync(
        "./artifacts/contracts/premium/PremiumAutomationManager.sol/PremiumAutomationManager.json",
        "utf-8"
    )
).abi;

const PremiumNotification = JSON.parse(
    fs.readFileSync(
        "./artifacts/contracts/premium/PremiumNotification.sol/PremiumNotification.json",
        "utf-8"
    )
).abi;



const PremiumMailRouter = JSON.parse(
    fs.readFileSync(
        "./artifacts/contracts/premium/PremiumMailRouter.sol/PremiumMailRouter.json",
        "utf-8"
    )
).abi;

const Setting = JSON.parse(
    fs.readFileSync(
        "./artifacts/contracts/premium/PremiumSetting.sol/PremiumSetting.json",
        "utf-8"
    )
).abi;

async function setUpReminder() {

    console.log('setUpReminder... at PremiumSetting');
    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(Setting);

    const txData = contract.methods
        .setUpReminder(manager, notification, sendMailRouter).encodeABI();

    //using ETH
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(1000000),
        gasPrice: await web3.eth.getGasPrice(),
        data: txData,
        to: premiumSetting,
        from: user,
    };

    const signedTx = await web3.eth.accounts.signTransaction(txObj, user_pk!);

    const result = await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
    console.log(result);
}

async function setParamsManager () {
    console.log('Set up Manager Params...');
    const txCount = await web3.eth.getTransactionCount(user);
    const contract = new web3.eth.Contract(Manager, manager);

    const txData = await contract.methods.
    setParams(i_link, i_registrar, keeperRegistry, premiumSetting, baseGasLimit, notification,sendMailRouter, 150 ).encodeABI();
    console.log(txData)
    //using ETH
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(4000000),
        gasPrice: await web3.eth.getGasPrice(),
        data: txData,
        to: manager,
        from: user,
    };

     const signedTx = await web3.eth.accounts.signTransaction(txObj, user_pk!);

    const result = await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
    console.log(result);

}  

async function setParamsMailRouter() {
    console.log('Setting params at PremiumMailRouter');

    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(PremiumMailRouter, sendMailRouter);

    const txData = contract.methods
        .setParams(mailBeforeActivation, mailActivated, mailReadyToActivate, premiumSetting, manager)
        .encodeABI();
    console.log(txData);

    //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(4000000),
        gasPrice: (await web3.eth.getGasPrice()).toString(),
        data: txData,
        to: sendMailRouter,
        from: user,

    };

    const signedTx = await web3.eth.accounts.signTransaction(txObj, user_pk!);

    const result = await web3.eth.sendSignedTransaction(
        signedTx.rawTransaction!
    );
    console.log(result);
   
    
    
}


async function setUpPush() {

    console.log('Set up PUSH.. at PremiumNotification')
    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(PremiumNotification, notification);

    const txData = contract.methods
        .setUpPush(enpsComm, channel, manager, premiumSetting)
        .encodeABI();
    console.log(txData);

    //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(2000000),
        gasPrice: (await web3.eth.getGasPrice()).toString(),
        data: txData,
        to: notification,
        from: user,

    };

    const signedTx = await web3.eth.accounts.signTransaction(txObj, user_pk!);

    const result = await web3.eth.sendSignedTransaction(
        signedTx.rawTransaction!
    );
    console.log(result);


}


async function main () {
    // When set up / replace Automation Manager, 
    // run these following functions to set up the reminder system
    // await setParamsManager();
    // await setPramramPremiumSetting();
    await setUpReminder();
    //Send Push 
    // await setUpPush();
    //  Send Mail
    // await setParamsMailRouter();

}
main().catch((error) => {
    console.log(error);
    process.exitCode = 1;
})