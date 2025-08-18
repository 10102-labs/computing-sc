
import Web3 from "web3";
import { ethers } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

import * as fs from "fs";
import { parseEther } from "ethers/lib/utils";
import { seconds } from "@nomicfoundation/hardhat-network-helpers/dist/src/helpers/time/duration";

const web3 = new Web3(process.env.RPC!);
const user_pk = process.env.PK;

const user = web3.eth.accounts.privateKeyToAccount(user_pk!).address;

const sendMailRouter = "0x01e8fbe1bc34d73d86a61ebc24a0e9509c0b8799";

const SendMailRouter = JSON.parse(
    fs.readFileSync(
        "./artifacts/contracts/premium/PremiumMailRouter.sol/PremiumMailRouter.json",
        "utf-8"
    )
).abi;


// Send Email Params
const ownerName = "Dat Tran";
const contractName = "Test Contract";
const lastTx = 1721865600;
const bufferTime = 86400;
const listBene = ["0x1234567890123456789012345678901234567890"];
const ownerEmail = "dat.tran2@sotatek.com";
const listBeneName = ["Dat", "Dat2"];
const listEmail = ["dat.tran2@sotatek.com", "dat.tran2@sotatek.com"];
const safeWallet = "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd";
const beneName = "Dat";
const beneEmail = "dat.tran2@sotatek.com";
const beneAddress = "0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3";
const activationDate = new Date().getTime();
async function sendEmailContractActivatedToOwner() {

    const activatedByBene = "0x1234567890abcdef1234567890abcdef12345678";
    const timeActivated = Math.floor(Date.now() / 1000);
    const safeWallet = "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd";

    // ListAsset[] sample
    const listAsset = [
        {
            listToken: "0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3",
            listAmount: ethers.utils.parseUnits("100", 18).toString(),
            listAssetName: "USDC",
        },
        {
            listToken: "0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3",
            listAmount: ethers.utils.parseUnits("50", 18).toString(),
            listAssetName: "DAI",
        },
    ];

    // BeneReceived[] sample
    const listBeneReceived = [
        {
            name: "Alice",
            beneAddress: "0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3",
            listAssetName: ["USDC", "DAI"],
            listAmount: [
                ethers.utils.parseUnits("60", 18).toString(),
                ethers.utils.parseUnits("30", 18).toString(),
            ],
        },
        {
            name: "Bob",
            beneAddress: "0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3",
            listAssetName: ["USDC"],
            listAmount: [ethers.utils.parseUnits("40", 18).toString()],
        },
    ];

    const contractAddress = "0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3";
    const remaining = true;


    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(SendMailRouter, sendMailRouter);

    const owner = await contract.methods.owner().call();
    console.log(owner);

    const txData = contract.methods
        .sendEmailContractActivatedToOwner(ownerEmail,
            contractName,
            activatedByBene,
            timeActivated,
            safeWallet,
            listAsset,
            listBeneReceived,
            contractAddress,
            remaining)
        .encodeABI();
    console.log(txData);

    //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(2000000),
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

async function sendEmailBeforeActivationToOwner() {

    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(SendMailRouter, sendMailRouter);

    const owner = await contract.methods.owner().call();
    console.log(owner);
    const txData = contract.methods
        .sendEmailBeforeActivationToOwner(ownerName, contractName, lastTx, bufferTime, listBene, ownerEmail)
        .encodeABI();
    console.log(txData);

    //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(2000000),
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

async function sendEmailActivatedToBeneWithRemaining() {
    const listToken = [
        "0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3", "0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3", "0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3", "0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3"];
    const listAmount = [ethers.utils.parseUnits("100", 18).toString(), ethers.utils.parseUnits("50", 18).toString(), ethers.utils.parseUnits("100", 18).toString(), ethers.utils.parseUnits("50", 18).toString()];
    const listAssetName = ["USDC", "DAI", "USDC", "DAI"];
    const contractAddress = "0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3"; 
    const txCount = await web3.eth.getTransactionCount(user);
    const contract = new web3.eth.Contract(SendMailRouter, sendMailRouter);
    const owner = await contract.methods.owner().call();
    console.log(owner);
    const txData = contract.methods
        .sendEmailActivatedToBeneWithRemaining(ownerName, ownerEmail, contractName, listToken, listAmount, listAssetName, contractAddress)
        .encodeABI();
    console.log(txData);
    //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(2000000),
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

async function sendEmailActivatedToBene() {
    const listToken = ["0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3", "0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3", "0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3", "0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3"];
    const listAmount = [ethers.utils.parseUnits("100", 18).toString(), ethers.utils.parseUnits("50", 18).toString(), ethers.utils.parseUnits("100", 18).toString(), ethers.utils.parseUnits("50", 18).toString()];
    const listAssetName = ["USDC", "DAI", "USDC", "DAI"];
    const contractAddress = "0x1c9DD7E71d25Ba94Efd770538c635D7aB57339F3";
    const txCount = await web3.eth.getTransactionCount(user);
    const contract = new web3.eth.Contract(SendMailRouter, sendMailRouter);
    const owner = await contract.methods.owner().call();
    console.log(owner);
    const txData = contract.methods
        .sendEmailActivatedToBene(ownerName, ownerEmail, contractName, listToken, listAmount, listAssetName, contractAddress)
        .encodeABI();
    //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(2000000),
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


async function sendActivatedMultisg() {
    const txCount = await web3.eth.getTransactionCount(user);
    const contract = new web3.eth.Contract(SendMailRouter, sendMailRouter);
    const owner = await contract.methods.owner().call();
    console.log(owner);
    const txData = contract.methods.sendMailActivatedMultisig(listBeneName, listEmail, contractName, safeWallet).encodeABI();
    console.log(txData);
    //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(2000000),
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

async function sendMailOwnerResetToBene() {
    const txCount = await web3.eth.getTransactionCount(user);
    const contract = new web3.eth.Contract(SendMailRouter, sendMailRouter);
    const owner = await contract.methods.owner().call();
    console.log(owner);
    const txData = contract.methods.sendMailOwnerResetToBene(listBeneName, listEmail, contractName).encodeABI();
    console.log(txData);
    //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(5000000),
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

async function sendEmailBeforeActivationToBeneficiary() {
    const txCount = await web3.eth.getTransactionCount(user);
    const contract = new web3.eth.Contract(SendMailRouter, sendMailRouter);
    const owner = await contract.methods.owner().call();
    console.log(owner);
    const timeCountdown = 1;
    const txData = contract.methods.sendEmailBeforeActivationToBeneficiary(listBeneName, contractName, timeCountdown, listEmail).encodeABI();
    console.log(txData);
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(10000000),
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

async function sendEmailBeforeLayer2ToLayer1() {
    const txCount = await web3.eth.getTransactionCount(user);
    const contract = new web3.eth.Contract(SendMailRouter, sendMailRouter);
    const owner = await contract.methods.owner().call();
    console.log(owner);
    const timeCountdown = 1;
    const txData = contract.methods.sendEmailBeforeLayer2ToLayer1(listBeneName,  listEmail, contractName, timeCountdown).encodeABI();
    console.log(txData);
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(10000000),
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

async function sendEmailBeforeLayer2ToLayer2() {
    const txCount = await web3.eth.getTransactionCount(user);
    const contract = new web3.eth.Contract(SendMailRouter, sendMailRouter);
    const owner = await contract.methods.owner().call();
    console.log(owner);
    const timeCountdown = 1;
    const txData = contract.methods.sendEmailBeforeLayer2ToLayer2(beneName, beneEmail, contractName, timeCountdown).encodeABI();
    console.log(txData);
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(10000000),
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

async function sendEmailBeforeLayer3ToLayer12() {
    const txCount = await web3.eth.getTransactionCount(user);
    const contract = new web3.eth.Contract(SendMailRouter, sendMailRouter);
    const owner = await contract.methods.owner().call();
    console.log(owner);
    const timeCountdown = 1;
    const txData = contract.methods.sendEmailBeforeLayer3ToLayer12(listBeneName, listEmail, contractName, timeCountdown).encodeABI();
    console.log(txData);
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(10000000),
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

async function sendEmailReadyToActivateToLayer1() {
    const txCount = await web3.eth.getTransactionCount(user);
    const contract = new web3.eth.Contract(SendMailRouter, sendMailRouter);
    const owner = await contract.methods.owner().call();
    console.log(owner);
    const timeCountdown = 1;
    const txData = contract.methods.sendEmailReadyToActivateToLayer1(listBeneName, listEmail, contractName).encodeABI();
    console.log(txData);
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(10000000),
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

async function sendEmailReadyToActivateLayer2ToLayer1() {
    const txCount = await web3.eth.getTransactionCount(user);
    const contract = new web3.eth.Contract(SendMailRouter, sendMailRouter);
    const owner = await contract.methods.owner().call();
    console.log(owner);
    const timeCountdown = 1;
    const txData = contract.methods.sendEmailReadyToActivateLayer2ToLayer1(listBeneName, listEmail, beneAddress, contractName, activationDate).encodeABI();
    console.log(txData);
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(10000000),
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

async function sendEmailReadyToActivateLayer3ToLayer12() {
    const txCount = await web3.eth.getTransactionCount(user);
    const contract = new web3.eth.Contract(SendMailRouter, sendMailRouter);
    const owner = await contract.methods.owner().call();
    console.log(owner);
    const timeCountdown = 1;
    const txData = contract.methods.sendEmailReadyToActivateLayer3ToLayer12(listBeneName, listEmail, contractName, activationDate, beneAddress).encodeABI();
    console.log(txData);
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(10000000),
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

async function sendEmailReadyToActivateLayer2ToLayer2() {
    const txCount = await web3.eth.getTransactionCount(user);
    const contract = new web3.eth.Contract(SendMailRouter, sendMailRouter);
    const owner = await contract.methods.owner().call();
    console.log(owner);
    const timeCountdown = 1;
    const txData = contract.methods.sendEmailReadyToActivateLayer2ToLayer2(beneName, beneEmail, contractName).encodeABI();
    console.log(txData);
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(10000000),
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

async function sendEmailReadyToActivateLayer3ToLayer3() {
    const txCount = await web3.eth.getTransactionCount(user);
    const contract = new web3.eth.Contract(SendMailRouter, sendMailRouter);
    const owner = await contract.methods.owner().call();
    console.log(owner);
    const timeCountdown = 1;
    const txData = contract.methods.sendEmailReadyToActivateLayer3ToLayer3(beneName, beneEmail, contractName).encodeABI();
    console.log(txData);
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(10000000),
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

async function main() {
    //Before Activation
    // await sendEmailBeforeActivationToOwner();
    // await sendEmailBeforeActivationToBeneficiary();
    // await sendEmailBeforeLayer2ToLayer1();
    // await sendEmailBeforeLayer2ToLayer2();
    // await sendEmailBeforeLayer3ToLayer12();

    //Ready to Activate
    // await sendEmailReadyToActivateToLayer1();
    // await sendEmailReadyToActivateLayer2ToLayer1();
    // await sendEmailReadyToActivateLayer3ToLayer12();    
    // await sendEmailReadyToActivateLayer2ToLayer2();
    // await sendEmailReadyToActivateLayer3ToLayer3();

    //Activated
    // await sendEmailContractActivatedToOwner();
    // await sendEmailActivatedToBene();
    // await sendEmailActivatedToBeneWithRemaining();
    await sendActivatedMultisg();
    // await sendMailOwnerResetToBene();

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});


