import { ethers } from "hardhat";

async function main() {

  const ServiceToken = await ethers.getContractFactory("ERC3525Service");
  const SlotRegistry = await ethers.getContractFactory("ERC3525SlotRegistry");

  await lock.deployed();

  console.log(`Lock with 1 ETH and unlock timestamp ${unlockTime} deployed to ${lock.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
