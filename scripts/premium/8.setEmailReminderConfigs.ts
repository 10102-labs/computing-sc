
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
function emailMapping(addr: string, email: string, name: string) {
    return { addr, email, name };
}
const premiumUser = "";
const ownerName = "DatTran2";
const ownerEmail = "dat.tran2@sotatek.com";
const timePriorActivation = 3*60;
// const  legacyAddresses : any[] = [];
//         const legacyData : any []= [];

const address0 = ethers.constants.AddressZero
const emptyConfig = emailMapping(address0, "", "");
const legacyAddresses = ["0xcdfca2a01cabefa3fe3745a6d82e136ca669abd7"];
const legacyData = [
    {
        cosigners: [],
        beneficiaries: [
            
            emailMapping("0x944A402a91c3D6663f5520bFe23c1c1eE77BCa92", "dat.tran2@sotatek.com", "dat"),
            // emailMapping("0xc3a20f9d15cfd2224038eccc8186c216366c4bfd", "dat.tran2@sotatek.com", "dat"),


        ],
        secondLine: emailMapping("0xC822DcaD6f4e7CD8B6e80CAd1AFA3F97ae8579CD", "dat.tran2@sotatek.com", "dat"),
        thirdLine:  emailMapping("0x81b96d6D59358FB53165aC7c88117AA8843F1F45", "dat.tran2@sotatek.com", "dat")
    },
];
async function main() {
    const setting = "0x283720b2102d97992Adc3E695A4d5a3690A95561";

    const Setting = JSON.parse(
        fs.readFileSync(
            "./artifacts/contracts/premium/PremiumSetting.sol/PremiumSetting.json",
            "utf-8"
        )
    ).abi;

    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(Setting, setting);

    const txData = contract.methods
        .setReminderConfigs(ownerName, ownerEmail, timePriorActivation, legacyAddresses, legacyData)
        .encodeABI();
    console.log(txData);

    //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(2000000),
        gasPrice: (await web3.eth.getGasPrice()).toString(),
        data: txData,
        to: setting,
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


// [[], ["0x8E4e77Cee39f54B7445441Ac35a6F6FA4F541b00", "bene1@example.com"], ["0xc3a20F9D15cfD2224038EcCC8186C216366c4BFd", "second1@example.com"], ["0x9189CD497326A4D94236a028094247A561D895c9", "third1@example.com"]]