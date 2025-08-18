import { ethers } from "ethers";

const safeAddress = "0x0e1A019FcbD0eE03C4361E82867BFA3796c90E36";

const GUARD_STORAGE_SLOT = "0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8";

const provider = new ethers.providers.JsonRpcProvider("https://eth-sepolia.public.blastapi.io"); // hoặc URL khác

async function getSafeGuard() {

  const rawValue = await provider.getStorageAt(safeAddress, GUARD_STORAGE_SLOT);

  const guardAddress = ethers.utils.getAddress("0x" + rawValue.slice(26));

  console.log("Guard address:", rawValue);
  return guardAddress;
}

getSafeGuard().catch(console.error);
