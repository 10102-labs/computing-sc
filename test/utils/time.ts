import { ethers } from "hardhat";

async function advanceBlock(): Promise<string> {
  return ethers.provider.send("evm_mine", []);
}
async function advanceBlockTo(blockNumber: number): Promise<void> {
  for (let i = await ethers.provider.getBlockNumber(); i < blockNumber; i++) {
    await advanceBlock();
  }
}
async function increase(value: number): Promise<void> {
  await ethers.provider.send("evm_increaseTime", [value]);
  await advanceBlock();
}

async function currentBlock() {
  return await ethers.provider.getBlockNumber();
}

async function currentTime(): Promise<number> {
  const time = (await ethers.provider.getBlock(await currentBlock())).timestamp;
  return time;
}

async function increaseTo(target: number): Promise<void> {
  const now = await latest();

  if (target < now)
    throw Error(
      `Cannot increase current time (${now}) to a moment in the past (${target})`
    );
  const diff = target - now;
  return increase(diff);
}

async function latest(): Promise<number> {
  const block = await ethers.provider.getBlock("latest");
  return block!.timestamp;
}

export {
  advanceBlock,
  advanceBlockTo,
  increase,
  increaseTo,
  latest,
  currentTime,
  currentBlock
};
