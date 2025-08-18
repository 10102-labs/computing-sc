
import Web3 from "web3";
import { ethers } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

import * as fs from "fs";
import { parseEther, parseUnits } from "ethers/lib/utils";


const web3 = new Web3(process.env.RPC!);
const user_pk = process.env.PK;

const user = web3.eth.accounts.privateKeyToAccount(user_pk!).address;

const usdt = "0x02f62735EaF5fFB56B629bC529e72801713f27cd"
const usdc = "0xC1Fa197B73577868516dDA2492d44568D9Ec884c";

async function main() {
    const token = usdc;
    const to = "0x7a79e586b7ac1244f742208efeefc9cc6a7d7476";
    const amount = parseUnits("1000", 6);

    const ERC20 = JSON.parse(
        fs.readFileSync(
            "./artifacts/contracts/mock/ERC20Token.sol/ERC20Token.json",
            "utf-8"
        )
    ).abi;

    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(ERC20, token);

    const txData = contract.methods
        .mint(to, amount.toString())
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
