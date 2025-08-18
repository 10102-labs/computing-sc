import { ethers } from "ethers";
import { parseUnits, formatUnits, formatEther } from "ethers/lib/utils";
import dotenv from "dotenv";
dotenv.config();

// RPC + signer là beneficiary
const SEPOLIA_RPC = "https://eth-sepolia.public.blastapi.io";
const provider = new ethers.providers.JsonRpcProvider(SEPOLIA_RPC);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY_BENEFICIARY!, provider);//0.5895

// Addresses
const LEGACY_ADDRESS = "0xf95352E50F6a37c57388D5C36B2fFE6df9fBCF99";
const USDC_ADDRESS = "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238";
const ADMIN_ADDRESS = "0x8B8F5248f7a0662bc17a785097BaFe0B3A850945";

async function main() {
  const legacyAbi = ["function activeLegacy(uint256 ,address[], bool)"];
  const erc20Abi = ["function balanceOf(address) view returns (uint256)"];

  const legacy = new ethers.Contract(LEGACY_ADDRESS, legacyAbi, wallet);
  const usdc = new ethers.Contract(USDC_ADDRESS, erc20Abi, wallet);

  const user = await wallet.getAddress();

  // Check balances before
  const adminEthBefore = await provider.getBalance(ADMIN_ADDRESS);
  const userEthBefore = await provider.getBalance(user);
  const adminUsdcBefore = await usdc.balanceOf(ADMIN_ADDRESS);
  const userUsdcBefore = await usdc.balanceOf(user);

  console.log("Calling activeLegacy...");
  const tx = await legacy.activeLegacy(3,[USDC_ADDRESS], false);
  await tx.wait();
  console.log(" Legacy activated!");

  // Check balances after
  const adminEthAfter = await provider.getBalance(ADMIN_ADDRESS);
  const userEthAfter = await provider.getBalance(user);
  const adminUsdcAfter = await usdc.balanceOf(ADMIN_ADDRESS);
  const userUsdcAfter = await usdc.balanceOf(user);

  // Deltas
  const adminEthDelta = adminEthAfter.sub(adminEthBefore);
  const userEthDelta = userEthAfter.sub(userEthBefore);
  const adminUsdcDelta = adminUsdcAfter.sub(adminUsdcBefore);
  const userUsdcDelta = userUsdcAfter.sub(userUsdcBefore);

  console.log("\n--- Balance Changes ---");
  console.log("Admin ETH +", formatEther(adminEthDelta));
  console.log("Admin USDC +", formatUnits(adminUsdcDelta, 6));
  console.log("Beneficiary ETH +", formatEther(userEthDelta));
  console.log("Beneficiary USDC +", formatUnits(userUsdcDelta, 6));
}

main().catch((err) => {
  console.error(" Failed:", err);
  process.exit(1);
});
