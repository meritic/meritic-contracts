import { ethers } from "hardhat";


async function main() {
	  
  const Registry = await ethers.getContractFactory("Registry");
  const registry = await Registry.deploy();
  await registry.deployed();
  console.log(`${registry.address}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});