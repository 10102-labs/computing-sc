
import Web3 from "web3";
import { ethers } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

import * as fs from "fs";
import { parseEther } from "ethers/lib/utils";


const web3 = new Web3(process.env.RPC!);
const user_pk = process.env.PK;

const user = web3.eth.accounts.privateKeyToAccount(user_pk!).address;

const userPremium = "0x7A79e586b7ac1244f742208eFeefC9cC6a7D7476";

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


    const txData = contract.methods
        .subrcribeByAdmin( userPremium, 23, "USDC")
        .encodeABI();
    console.log(txData);

    //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(10000000),
        gasPrice: (await web3.eth.getGasPrice()).toString(),
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
