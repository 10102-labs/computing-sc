import Web3 from "web3";
import * as dotenv from "dotenv";

dotenv.config();

import * as fs from "fs";

const web3 = new Web3(process.env.SEPOLIA_RPC_URL!);
const user_pk = process.env.PK;

const user = web3.eth.accounts.privateKeyToAccount(user_pk!).address;
const wallet = web3.eth.accounts.privateKeyToAccount(user_pk!);

// Helper functions to replace ethers utils
// function parseUnits(value: string, decimals: number): string {
//     return web3.utils.toWei(value, decimals === 6 ? 'mwei' : 'ether');
// }

function formatUnits(value: string, decimals: number): string {
    return web3.utils.fromWei(value, decimals === 6 ? 'mwei' : 'ether');
}
// Contract addresses
const paymentContract = "0xdc3818bc887b91ffaa02049d9667f93b295fad5c";
const usdcAddress = "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238"; // USDC on Sepolia (từ script bạn)

// Standard ERC20 ABI
const ERC20_ABI = [
    {
        "constant": false,
        "inputs": [
            {"name": "_spender", "type": "address"},
            {"name": "_value", "type": "uint256"}
        ],
        "name": "approve",
        "outputs": [{"name": "", "type": "bool"}],
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {"name": "_to", "type": "address"},
            {"name": "_value", "type": "uint256"}
        ],
        "name": "transfer",
        "outputs": [{"name": "", "type": "bool"}],
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [{"name": "_owner", "type": "address"}],
        "name": "balanceOf",
        "outputs": [{"name": "balance", "type": "uint256"}],
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "decimals",
        "outputs": [{"name": "", "type": "uint8"}],
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {"name": "_owner", "type": "address"},
            {"name": "_spender", "type": "address"}
        ],
        "name": "allowance",
        "outputs": [{"name": "", "type": "uint256"}],
        "type": "function"
    }
];


function parseUnits(value: string, decimals: number): string {
    const [intPart, fracPart = ""] = value.split(".");
    const paddedFrac = (fracPart + "0".repeat(decimals)).slice(0, decimals);
    return BigInt(intPart + paddedFrac).toString();
}

async function approveUSDC(amount: string) {
    console.log(`\n=== APPROVING ${amount} USDC ===`);
    
    const usdcContract = new web3.eth.Contract(ERC20_ABI, usdcAddress);
    const txCount = await web3.eth.getTransactionCount(user);
    
    // Convert amount to proper decimals (USDC has 6 decimals)
    const amountWeiStr = parseUnits(amount, 6);
    
    console.log(`Approving ${amount} USDC (${amountWeiStr}) for payment contract...`);
    
    const txData = usdcContract.methods
        .approve(paymentContract, amountWeiStr)
        .encodeABI();
    
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(100000),
        gasPrice: (await web3.eth.getGasPrice()).toString(),
        data: txData,
        to: usdcAddress,
        from: user,
    };
    
    console.log("Signing approve transaction...");
    const signedTx = await web3.eth.accounts.signTransaction(txObj, user_pk!);
    
    console.log("Sending approve transaction...");
    const result = await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
    
    console.log("✅ Approve transaction successful!");
    console.log("Transaction hash:", result.transactionHash);
    
    return result;
}

async function transferUSDC(amount: string) {
    console.log(`\n=== TRANSFERRING ${amount} USDC TO PAYMENT CONTRACT ===`);
    
    const usdcContract = new web3.eth.Contract(ERC20_ABI, usdcAddress);
    const txCount = await web3.eth.getTransactionCount(user);
    
    // Convert amount to proper decimals (USDC has 6 decimals)
    const amountWeiStr = parseUnits(amount, 6);
    
    console.log(`Transferring ${amount} USDC (${amountWeiStr}) to payment contract...`);
    
    const txData = usdcContract.methods
        .transfer(paymentContract, amountWeiStr)
        .encodeABI();
    
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(100000),
        gasPrice: (await web3.eth.getGasPrice()).toString(),
        data: txData,
        to: usdcAddress,
        from: user,
    };
    
    console.log("Signing transfer transaction...");
    const signedTx = await web3.eth.accounts.signTransaction(txObj, user_pk!);
    
    console.log("Sending transfer transaction...");
    const result = await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
    
    console.log("✅ Transfer transaction successful!");
    console.log("Transaction hash:", result.transactionHash);
    
    return result;
}

async function sendETH(amount: string) {
    console.log(`\n=== SENDING ${amount} ETH TO PAYMENT CONTRACT ===`);
    
    const txCount = await web3.eth.getTransactionCount(user);
    const amountWeiStr = parseUnits(amount, 18);
    
    console.log(`Sending ${amount} ETH (${amountWeiStr}) to payment contract...`);
    
    const txObj = {
        nonce: txCount,
        gas: web3.utils.toHex(21000), // Standard ETH transfer gas
        gasPrice: (await web3.eth.getGasPrice()).toString(),
        to: paymentContract,
        from: user,
        value: web3.utils.toHex(amountWeiStr),
    };
    
    console.log("Signing ETH transfer transaction...");
    const signedTx = await web3.eth.accounts.signTransaction(txObj, user_pk!);
    
    console.log("Sending ETH transfer transaction...");
    const result = await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
    
    console.log("✅ ETH transfer transaction successful!");
    console.log("Transaction hash:", result.transactionHash);
    
    return result;
}

async function checkBalances() {
    console.log("\n=== CHECKING BALANCES ===");
    
    const usdcContract = new web3.eth.Contract(ERC20_ABI, usdcAddress);
    
    // User balances
    const userUsdcBalance = await usdcContract.methods.balanceOf(user).call() as string;
    const userEthBalanceRaw = await web3.eth.getBalance(user);
    const userEthBalance = userEthBalanceRaw.toString();
    const allowance = await usdcContract.methods.allowance(user, paymentContract).call() as string;
    
    // Payment contract balances
    const paymentUsdcBalance = await usdcContract.methods.balanceOf(paymentContract).call() as string;
    const paymentEthBalanceRaw = await web3.eth.getBalance(paymentContract);
    const paymentEthBalance = paymentEthBalanceRaw.toString();
    
    console.log(`\n--- USER BALANCES ---`);
    console.log(`Address: ${user}`);
    console.log(`ETH Balance: ${formatUnits(userEthBalance, 18)} ETH`);
    console.log(`USDC Balance: ${formatUnits(userUsdcBalance, 6)} USDC`);
    console.log(`USDC Allowance: ${formatUnits(allowance, 6)} USDC`);
    
    console.log(`\n--- PAYMENT CONTRACT BALANCES ---`);
    console.log(`Address: ${paymentContract}`);
    console.log(`ETH Balance: ${formatUnits(paymentEthBalance, 18)} ETH`);
    console.log(`USDC Balance: ${formatUnits(paymentUsdcBalance, 6)} USDC`);
    
    return {
        user: {
            eth: userEthBalance,
            usdc: userUsdcBalance,
            allowance: allowance
        },
        paymentContract: {
            eth: paymentEthBalance,
            usdc: paymentUsdcBalance
        }
    };
}

async function depositUSDCAndETH(usdcAmount: string, ethAmount: string) {
    console.log(`\n🚀 DEPOSITING ${usdcAmount} USDC AND ${ethAmount} ETH TO PAYMENT CONTRACT`);
    
    try {
        // Step 1: Check balances
        const balancesBefore = await checkBalances();
        
        const usdcAmountWei = parseUnits(usdcAmount, 6);
        const ethAmountWei = parseUnits(ethAmount, 18);
        
        // Check if user has enough balance
        if (BigInt(balancesBefore.user.usdc) < BigInt(usdcAmountWei)) {
            console.log(`❌ Insufficient USDC balance. You have ${formatUnits(balancesBefore.user.usdc, 6)} USDC but trying to send ${usdcAmount} USDC`);
            return;
        }
        
        if (BigInt(balancesBefore.user.eth) < BigInt(ethAmountWei)) {
            console.log(`❌ Insufficient ETH balance. You have ${formatUnits(balancesBefore.user.eth, 18)} ETH but trying to send ${ethAmount} ETH`);
            return;
        }
        
        // Step 2: Transfer USDC (no approval needed for direct transfer)
        await transferUSDC(usdcAmount);
        
        // Wait a bit
        console.log("⏳ Waiting 3 seconds before ETH transfer...");
        await new Promise(resolve => setTimeout(resolve, 3000));
        
        // Step 3: Send ETH
        await sendETH(ethAmount);
        
        // Step 4: Check final balances
        console.log("\n⏳ Waiting 5 seconds for final balance check...");
        await new Promise(resolve => setTimeout(resolve, 5000));
        
        console.log("\n=== FINAL BALANCES ===");
        await checkBalances();
        
        console.log("\n🎉 All deposits completed successfully!");
        
    } catch (error) {
        console.error("❌ Error during deposit:", error);
        throw error;
    }
}

async function main() {
    try {
        console.log("🚀 Starting USDC and ETH Deposit Script");
        console.log(`User: ${user}`);
        console.log(`Payment Contract: ${paymentContract}`);
        console.log(`USDC Address: ${usdcAddress}`);
        
        // Check initial balances
        await checkBalances();
        
        // Deposit amounts - change these values as needed
        const usdcAmount = "10";      // 1 USDC
        const ethAmount = "0.001";   // 0.001 ETH
        
        await depositUSDCAndETH(usdcAmount, ethAmount);
        
    } catch (error) {
        console.error("❌ Error occurred:", error);
        throw error;
    }
}

// Individual functions for custom use
async function depositOnlyUSDC(amount: string) {
    console.log(`\n=== DEPOSITING ONLY ${amount} USDC ===`);
    await transferUSDC(amount);
}

async function depositOnlyETH(amount: string) {
    console.log(`\n=== DEPOSITING ONLY ${amount} ETH ===`);
    await sendETH(amount);
}

// Export functions
export { 
    checkBalances, 
    transferUSDC, 
    sendETH, 
    depositUSDCAndETH, 
    depositOnlyUSDC, 
    depositOnlyETH,
    approveUSDC // Keep approve function if needed for other contracts
};

// Main execution
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});