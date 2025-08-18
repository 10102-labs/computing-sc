
import Web3 from "web3";
import { ethers } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

import * as fs from "fs";
import { parseEther, parseUnits } from "ethers/lib/utils";


const web3 = new Web3(process.env.RPC!);
const user_pk = process.env.PK;

const user = web3.eth.accounts.privateKeyToAccount(user_pk!).address;


async function main() {
    const token = "0x02f62735EaF5fFB56B629bC529e72801713f27cd";
    const to = "0xC822DcaD6f4e7CD8B6e80CAd1AFA3F97ae8579CD";
    const amount = parseUnits("100000", 6);

    const ERC20 = JSON.parse(
        fs.readFileSync(
            "./artifacts/contracts/mock/ERC20Token.sol/ERC20Token.json",
            "utf-8"
        )
    ).abi;

    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(ERC20, token);

    const txData = contract.methods
        .transfer(to, amount.toString())
        .encodeABI();
    console.log(txData);

     //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(2000000),
        gasPrice: (await web3.eth.getGasPrice()).toString(),
        data: txData,
        to: token,
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
