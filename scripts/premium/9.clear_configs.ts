
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

const legacyAddresses = ["0x0cb77f164ce3280aee282b037b6e4cecda6dd0f9"];

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
            .clearLegacyConfig(legacyAddresses)
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


