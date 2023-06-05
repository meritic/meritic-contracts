import { ethers } from "hardhat";
import { config as dotEnvConfig } from "dotenv";

// const hardhatUSDCAddress = process.env.HARDHAT_USDC_CONTRACT_ADDRESS;

async function main() {
	const WUSDC = await ethers.getContractFactory("WUSDC");
  	const wusdc = await WUSDC.deploy();
  	await wusdc.deployed();
  	console.log(`${wusdc.address}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});