import Web3 from "web3";
import { ethers } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

import * as fs from "fs";
import { parseEther } from "ethers/lib/utils";


const web3 = new Web3(process.env.SEPOLIA_RPC_URL!);
const user_pk = process.env.PK;

const user = web3.eth.accounts.privateKeyToAccount(user_pk!).address;
const wallet = web3.eth.accounts.privateKeyToAccount(user_pk!);

const swap = {
    router : "0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008",
    weth : "0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9",
}

async function genMessage(legacyAddress: string, timestamp: bigint): Promise<string> {
    const message = `I agree to legacy at address ${legacyAddress.toLowerCase()} at timestamp ${timestamp}`;
    return message;
}


async function main() {
    const legacyRouter = "0xEBBABba749062f1D550eDc9321b6770BC00b9b9F";

    const LegacyRouter = JSON.parse(
        fs.readFileSync(
            "./artifacts/contracts/forwarding/TransferLegacyEOAContractRouter.sol/TransferEOALegacyRouter.json",
            "utf-8"
        )
    ).abi;

    console.log(user);

    const txCount = await web3.eth.getTransactionCount(user);


    const mainConfig = {
        name: "abc",
        note: "nothing",
        nickNames: ["dadad"],
        distributions: [
            {
                user: "0x944A402a91c3D6663f5520bFe23c1c1eE77BCa92",
                percent: 100
            }
        ]
    };

    const extraConfig = {
        lackOfOutgoingTxRange: 1,
        delayLayer2: 0,
        delayLayer3: 0
    };

    const layer2Distribution = {
        user: "0x0000000000000000000000000000000000000000",
        percent: 0
    };

    const layer3Distribution = {
        user: "0x0000000000000000000000000000000000000000",
        percent: 0
    };

    const nickName2 = "";
    const nickName3 = "";

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
        .createLegacy(mainConfig,
            extraConfig,
            layer2Distribution,
            layer3Distribution,
            nickName2,
            nickName3,
            //swap,
            timestamp,
            signature.signature)
        .encodeABI();
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