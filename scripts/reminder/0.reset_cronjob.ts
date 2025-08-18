
import Web3 from "web3";
import { ethers } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

import * as fs from "fs";
import { parseEther } from "ethers/lib/utils";


const web3 = new Web3(process.env.RPC!);
const user_pk = process.env.PK;

const user = web3.eth.accounts.privateKeyToAccount(user_pk!).address;

const cronjobOfUsers: string[] = [

    // "0x74B39049851D8dE8390e665CA4A59903B25E373E",
    "0xb4ff905503c18e0ab481eccbbba1b2bcfd80c167",
"0x3968c89b75b077a7cd6f41e2d6055c5874ae2252",
"0x944a402a91c3d6663f5520bfe23c1c1ee77bca92",
"0x0793b9e34f151758945f52492ae5627c295e245f",
"0x03f209c5903aaf07928db21465bd8f9840da0397",
"0xd2bec19764bec1bcae559fdc6e995c550349e4c5",
"0x944a402a91c3d6663f5520bfe23c1c1ee77bca92",
"0xc9cc5296c36a15e76738f935bb78fd4a8f08a64b",
"0xd9191865edb3e187e9f6d016382fd4aacc4f26bb",
"0x906d8dfba69ac48aa766d85a6af36ad62b907644",
"0x97a1f83c71e422198de62afbdec56d23687c7828",
"0x6f3b78197cd55a38d43cb5c3f9407908d72d31de",
"0x944a402a91c3d6663f5520bfe23c1c1ee77bca92",
"0x9db25c6bcdae1d6913df5d38606eb907f0f4945b",
"0x8e4e77cee39f54b7445441ac35a6f6fa4f541b00",
"0xbaf7f7316ad3e1e45a40aafe651539fc1db37552",
"0x8e80a0555b5aa1c95fab45d2f5cd82c9c30bf0c4",
"0x0a9e31f4f43b28feb314e1ab393a3371218c5a28",
"0x58b85e5e5fee801facc212b1a6f1734816def39a",
"0x5044964a085f4f4d9fb7d018d00efda4b4175418",
"0xf1c1989ddf5a732b61b20684e04d97cc1bc67b55",
"0xca6e38a54d37240a5ae0ef8303993e2e6fdb4a6f",
"0x5b65ae8fe34719127369999eb7f206a3768c93e2",
"0x78da44df3c104a1bbbf50358b8e09b15a3f2f63f",
"0x13e58da2d49b1452ea52e37696041a03dca4675e",
"0x74b39049851d8de8390e665ca4a59903b25e373e",
"0x1330cfb57dbdb83fa20e8a159d42cb05d503b8d5",
"0xe71ffa7cedb046c409813c86ec5c728c3e62fe03",
"0x94fa720ed9161d2f68ee35a63895f0da8927ffff",
"0x171b15e3237a931e66b7d6002f1bd846c558c308",
"0xe5d62c23c2987bae7f7a5a171eefb9bf83a0333e",
"0x78da44df3c104a1bbbf50358b8e09b15a3f2f63f",
"0x28e899f42aa1b4ee9d2deb46059c4c75977ddc88",
"0xc46962612549eceec23f2849b1497f87465ee7e4",
"0xff170fdcdd4f0016123157e620aca9d982c2e52a",
"0x4ec4d02c1f505fb324831fe2d31328df3c57660a",
"0xca6e38a54d37240a5ae0ef8303993e2e6fdb4a6f",
"0x56badd82c41e0a89fdc4a96998753b89cba5cd11",
"0x968479b61e6a6d8414c22ee8836616d3dc4bbe57",
"0xd1e849aeb20a7108742c919fc781ef728c05cb0e",
"0x944a402a91c3d6663f5520bfe23c1c1ee77bca92",
"0x731f0371e85e59e400529a05cf9d5eb13b284028",
"0x9cbf669b5f96b4b78f1d0b3ddb2ec6c157dbf276",
"0xae87e94fd7bcbcdba70a497037e313712b810941",
"0x480158aa49760e3761efe211ca6bc24ef2782af9",
"0x76248079002bc243939afb7fd42116dbe3111125",
"0xc12eafa6ce068d85c052afdea5e55417241cc737",
"0x34ea4a2dfedc4c49f0817bc772ed22847f508b33",
"0xb1e39b3f5bbe8c81bb91552b3225066d4d39df6d",
"0x03d36349cc5926244119aadcdbd456b67c90e374",
"0x5044964a085f4f4d9fb7d018d00efda4b4175418",
"0xd72735c1618a29b7a6ad171090ac97166aa7f50b",
"0x06262f46cf1b43d2d046ffee993530e2b23ed355",

];



async function main() {
    const automationManger = "0x674552d6a2E3F47DfacF362c874eeBa933c82561";

    const AutomationManger = JSON.parse(
        fs.readFileSync(
            "./artifacts/contracts/premium/PremiumAutomationManager.sol/PremiumAutomationManager.json",
            "utf-8"
        )
    ).abi;


    const contract = new web3.eth.Contract(AutomationManger, AutomationManger);

    const txCount = await web3.eth.getTransactionCount(user);

    const txData = contract.methods
        .resetCronjobs(cronjobOfUsers)
        .encodeABI();
    console.log(txData);

    //using ETH
    const calculateFeeData = await web3.eth.calculateFeeData()
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(2000000),
        gasPrice: (await web3.eth.getGasPrice()).toString(),
        data: txData,
        to: automationManger,
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
