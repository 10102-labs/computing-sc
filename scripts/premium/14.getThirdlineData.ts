
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

const legacyAddresses = "0xa1622A2f5151555b34E5d2Ee504025d5fA664587";

    async function main() {
        const setting = "0x6a744ed43AC1d94dab1efCBE833e5783Efe77613";

        const Setting = JSON.parse(
            fs.readFileSync(
                "./artifacts/contracts/premium/PremiumSetting.sol/PremiumSetting.json",
                "utf-8"
            )
        ).abi;

        const txCount = await web3.eth.getTransactionCount(user);

        const contract = new web3.eth.Contract(Setting, setting);

        const txData = await contract.methods
            .getThirdLineData(legacyAddresses)
            .call();
        console.log(txData);

       


    }

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});


