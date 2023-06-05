import { ethers } from "hardhat";
import { config as dotEnvConfig } from "dotenv";

const registryAddress = process.env.SLOT_REGISTRY_CONTRACT_ADDRESS;
const WUSDCContractAddress = process.env.WUSDC_CONTRACT_ADDRESS;

async function main() {

    const ServiceToken = await ethers.getContractFactory("Service");
  
  const mWETH = await ethers.getContractFactory("WUSDC");
  const Swap = await ethers.getContractFactory("Swap");
    
  const mweth = await mWETH.deploy();
  const mswap = await Swap.deploy(mweth.address);

  await mweth.deployed();
  await mswap.deployed();

  
  console.log(`Registry contract deployed to ${registryAddress}`);
  console.log(`Swap contract deployed to ${mswap.address}`);
  
  const name = "Meritic";
  const symbol = "MERIT";

  const proxyAddress = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

  const lockAdmin = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
  
  
  /*address proxyServiceAddress_,
	address slotRegistry_,
	string memory name_, 
	string memory symbol_, 
	string memory baseURI_, 
	string memory contractDescription_,
	string memory valueToken_,
	uint8 decimals_*/
        		
        		
        		
  const serviceToken = await ServiceToken.deploy(proxyAddress, registry.address, lockAdmin, name, symbol);
  await serviceToken.deployed();
    
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});