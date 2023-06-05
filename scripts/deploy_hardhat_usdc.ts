import { ethers } from "hardhat";


async function main() {
	  
	var x = process.argv[0];  
	var y = process.argv[1];  
	
	console.log(process.argv);

	
  	/*const HardhatUSDC = await ethers.getContractFactory("HardhatUSDC");
    const USDCToken = await HardhatUSDC.deploy();
    await USDCToken.deployed();
    
  	console.log(`${USDCToken.address}`);*/

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});