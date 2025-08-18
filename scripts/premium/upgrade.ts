import Web3 from "web3";
import * as dotenv from "dotenv";
import * as fs from "fs";

dotenv.config();

const web3 = new Web3(process.env.RPC!);
const user_pk = process.env.PK!;
const user = web3.eth.accounts.privateKeyToAccount(user_pk).address;

async function upgradeProxy() {
    const proxyAddress = "0xB8FCc4eB187816014293387483AfeeE96d835CEF";
    const newImplementation = "0x4693CC2D9d1FCE4628F4d7BB6BdC8eEF7628fA62";
    const proxyAdminAddress = "0x04F77bbc5AE606e0e1424A6e85762a95114AcBe4";
    const ProxyAdminABI = [
        {
            "inputs": [
                { "internalType": "address", "name": "proxy", "type": "address" },
                { "internalType": "address", "name": "implementation", "type": "address" }
            ],
            "name": "upgrade",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        }
    ];
    const proxyAdmin = new web3.eth.Contract(ProxyAdminABI, proxyAdminAddress);

  const txData = proxyAdmin.methods.upgrade(proxyAddress, newImplementation).encodeABI();

  const txCount = await web3.eth.getTransactionCount(user);
  const gasPrice = await web3.eth.getGasPrice();

  const txObj = {
    nonce: txCount,
    gas: web3.utils.toHex(10000000),
    gasPrice: gasPrice,
    data: txData,
    to: proxyAdminAddress,
    from: user,
  };

  const signedTx = await web3.eth.accounts.signTransaction(txObj, user_pk);
  const result = await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
  console.log("Upgrade successful:", result.transactionHash);
}

upgradeProxy().catch((error) => {
  console.error("Upgrade failed:", error);
  process.exit(1);
});
