
import Web3 from "web3";
import { ethers } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

import * as fs from "fs";
import { parseEther } from "ethers/lib/utils";


const web3 = new Web3(process.env.RPC!);
const user_pk = process.env.PK;

const user = web3.eth.accounts.privateKeyToAccount(user_pk!).address;

async function main() {
    const keeperRegistry = "0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad";

    const KeeperRegistry = JSON.parse(
        fs.readFileSync(
            "./artifacts/contracts/premium/PremiumAutomationManager.sol/IKeeperRegistryMaster.json",
            "utf-8"
        )
    ).abi;

    const txCount = await web3.eth.getTransactionCount(user);

    const contract = new web3.eth.Contract(KeeperRegistry, keeperRegistry);

    const forwarder = await contract.methods
        .getForwarder("29189315692236367115449161869224843662479522935263686428533370753632275574227")
        .call();
      console.log('Forwarder: ', forwarder);

    const balanceOf = await contract.methods
        .getBalance("29189315692236367115449161869224843662479522935263686428533370753632275574227")
        .call();
    console.log(balanceOf);

    const minBalance = await contract.methods
        .getMinBalance("29189315692236367115449161869224843662479522935263686428533370753632275574227")
        .call();
    console.log('Min balance', minBalance);

    const minBalanceForUpkeep = await contract.methods
        .getMinBalanceForUpkeep("29189315692236367115449161869224843662479522935263686428533370753632275574227")
        .call();    
    console.log('Min balance for upkeep', minBalanceForUpkeep);

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
