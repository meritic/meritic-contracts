import { ethers } from "hardhat";


async function main() {
	  
  const SlotRegistry = await ethers.getContractFactory("SlotRegistry");
  const registry = await SlotRegistry.deployed();
  console.log(
    `Contract deployed to ${registry.address}`
  );
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});