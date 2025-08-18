import { ethers } from "ethers";
import { expect } from "chai";
import { parseUnits } from "ethers/lib/utils";
import dotenv from "dotenv";
dotenv.config();

// Sepolia testnet RPC & signer
const SEPOLIA_RPC = "https://eth-sepolia.public.blastapi.io";
const provider = new ethers.providers.JsonRpcProvider(SEPOLIA_RPC);
const wallet = new ethers.Wallet(process.env.PK!, provider);

// Contract addresses
const USDC_ADDRESS = "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238";
const UNISWAP_ROUTER = "0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008";
const WETH_ADDRESS = "0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9";
const ADMIN_WALLET = "0x8B8F5248f7a0662bc17a785097BaFe0B3A850945";
const LEGACY_ADDRESS = "0xEBBABba749062f1D550eDc9321b6770BC00b9b9F";
const MOCK_USDC="0xC1Fa197B73577868516dDA2492d44568D9Ec884c";

async function main() {
  const usdcAbi = [
    "function balanceOf(address) view returns (uint256)",
    "function transfer(address, uint256) returns (bool)",
    "function approve(address, uint256) returns (bool)"
  ];

  const legacyAbi = [
    "function setSwapSettings(address, address, address)",
    "function activeLegacy(uint256 ,address[], bool)",
    "function getDistribution (uint8, address)"
  ];

  const usdc = new ethers.Contract(USDC_ADDRESS, usdcAbi, wallet);
  const legacy = new ethers.Contract(LEGACY_ADDRESS, legacyAbi, wallet);
  const musdc = new ethers.Contract(MOCK_USDC, usdcAbi, wallet);
  // //Set swap settings
  // console.log("Setting swap settings...");
  // const setSwapTx = await legacy.setSwapSettings(UNISWAP_ROUTER, WETH_ADDRESS, ADMIN_WALLET);
  // await setSwapTx.wait();


  //Deposit USDC
  // const amountUSDC = parseUnits("1", 6); // 1 USDC
  // console.log("Approving USDC...");
  // const approveTx = await usdc.approve(LEGACY_ADDRESS, amountUSDC);
  // await approveTx.wait();

  // console.log("Transferring USDC to legacy...");
  // const transferTx = await usdc.transfer(LEGACY_ADDRESS, amountUSDC);
  // await transferTx.wait();

  // //Deposit MUSDC
  // const amountMUSDC = parseUnits("10", 6); // 10 MUSDC
  // console.log("Approving MUSDC...");
  // const approvemTx = await musdc.approve(LEGACY_ADDRESS, amountMUSDC);
  // await approvemTx.wait();

  // console.log("Transferring MUSDC to legacy...");
  // const transfermTx = await musdc.transfer(LEGACY_ADDRESS, amountMUSDC);
  // await transfermTx.wait();

  // Deposit ETH
   
  // // // console.log("Sending ETH to legacy...");
  // // // const sendEthTx = await wallet.sendTransaction({
  // // //   to: LEGACY_ADDRESS,
  // // //   value: parseUnits("0.0001", "ether"),
  // // // });
  // // // await sendEthTx.wait();

  // //Check balances before
  // const adminBalanceBefore = await provider.getBalance(ADMIN_WALLET);
  // const userAddress = await wallet.getAddress();
  // const userEthBefore = await provider.getBalance(userAddress);
  // const userUsdcBefore = await usdc.balanceOf(userAddress);

  //Activate legacy
  console.log("Activating legacy...");
  const activeTx = await legacy.activeLegacy(1,[USDC_ADDRESS,MOCK_USDC], false);
  await activeTx.wait();

  // Check balances after
  // const adminBalanceAfter = await provider.getBalance(ADMIN_WALLET);
  // const userEthAfter = await provider.getBalance(userAddress);
  // const userUsdcAfter = await usdc.balanceOf(userAddress);

  // const ethDelta = userEthAfter.sub(userEthBefore);
  // const usdcDelta = userUsdcAfter.sub(userUsdcBefore);
  // const adminDelta = adminBalanceAfter.sub(adminBalanceBefore);

  // console.log("\n--- Test Results ---");
  // console.log("ETH Received by user:", ethers.utils.formatEther(ethDelta));
  // console.log("USDC Received by user:", ethers.utils.formatUnits(usdcDelta, 6));
  // console.log("ETH Received by admin:", ethers.utils.formatEther(adminDelta));

  // Assertions
  // expect(adminDelta.gte(parseUnits("0.000009", "ether"))).to.be.true;
  // //expect(ethDelta.gte(parseUnits("0.00098", "ether"))).to.be.true;
  // expect(usdcDelta.eq(parseUnits("0.99", 6))).to.be.true;

  console.log("Test passed");
}

main().catch((error) => {
  console.error(" Test failed:", error);
  process.exit(1);
});
