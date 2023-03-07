import { ethers } from "hardhat";


async function main() {
	  
  const SlotRegistry = await ethers.getContractFactory("SlotRegistry");
  const ServiceToken = await ethers.getContractFactory("Service");
  
  
  const registry = await SlotRegistry.deploy();
  await registry.deployed();
  
  
  
  console.log(
    `Contract deployed to ${registry.address}`
  );
  const name = "Meritic";
  const symbol = "MERIT";
    
    const serviceOwner = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
    const proxyAddress = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
    const slotRegistry = registry.address;
    const lockAdmin = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
    
    const serviceToken = await ServiceToken.deploy(serviceOwner, proxyAddress, registry.address, lockAdmin, name, symbol);
    await serviceToken.deployed();
    
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});