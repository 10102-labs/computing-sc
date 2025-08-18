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

async function main() {
    const legacyRouter = "0xb12b4A1bbe14b6Fe0b7D2cBD5B56DC09e7cc3a5d";

    const LegacyRouter = JSON.parse(
        fs.readFileSync(
            "./artifacts/contracts/forwarding/TransferLegacyEOAContractRouter.sol/TransferEOALegacyRouter.json",
            "utf-8"
        )
    ).abi;

    console.log(user);

    const txCount = await web3.eth.getTransactionCount(user);


    const mainConfig = {
        name: "Test claim remaming email",
        note: "nothing",
        nickNames: ["dadad"],
        distributions: [
            {
                user: "0x944A402a91c3D6663f5520bFe23c1c1eE77BCa92",
                percent: 100
            },
            // {
            //     user: "0xc3a20f9d15cfd2224038eccc8186c216366c4bfd",
            //     percent: 80
            // },
            // {
            //     user: "0x85230a4fc826149cd7cbf3ad404420a28596d6cc",
            //     percent: 50
            // }
        ]
    };

    const extraConfig = {
        lackOfOutgoingTxRange: 7*60,
        delayLayer2: 6*60,
        delayLayer3: 6*60
    };

    const layer2Distribution = {
        user: "0xC822DcaD6f4e7CD8B6e80CAd1AFA3F97ae8579CD",
        percent: 100
    };

    const layer3Distribution = {
        user: "0x81b96d6D59358FB53165aC7c88117AA8843F1F45",
        percent: 100
    };

    const nickName2 = "L2";
    const nickName3 = "L3";

    const contract = new web3.eth.Contract(LegacyRouter, legacyRouter);

    const timestamp = (await web3.eth.getBlock("latest")).timestamp;
    const legacyAddress = await contract.methods.getNextLegacyAddress(user).call();
    if (!legacyAddress || typeof legacyAddress !== "string") {
        throw new Error("Failed to fetch legacy address");
    }
    console.log(legacyAddress);
    const message = await genMessage(legacyAddress, timestamp);
    console.log(message);
    const signature = wallet.sign(message);
    console.log('signature', signature.signature);

    const txData = contract.methods
        .createLegacy(
            mainConfig,
            extraConfig,
            layer2Distribution,
            layer3Distribution,
            nickName2,
            nickName3,
            timestamp,
            signature.signature)
        .encodeABI();
    console.log(txData);

    //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(8000000),
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