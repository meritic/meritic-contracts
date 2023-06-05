import { ethers } from "hardhat";


async function main() {
	  
  const SlotRegistry = await ethers.getContractFactory("SlotRegistry");
  const registry = await SlotRegistry.deploy();
  await registry.deployed();
  console.log(`${registry.address}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});