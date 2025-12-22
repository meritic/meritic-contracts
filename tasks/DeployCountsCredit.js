//import { task } from "hardhat/config";
const { task }  = require('hardhat/config');

//const { ethers } = require('ethers');
//const ethers = require('hardhat');
//const { config } =  require('dotenv');
const fs = require('fs');
const path = require('path'); 







const registryAddress = process.env.SLOT_REGISTRY_CONTRACT_ADDRESS;
const WUSDCContractAddress = process.env.WUSDC_CONTRACT_ADDRESS;

const MERITIC_TEST_MKT_SERVICE_ADDRESS = process.env.MERITIC_TEST_MKT_SERVICE_ADDRESS;
const MERITIC_TEST_MKT_SERVICE_PRIVATE_KEY = process.env.MERITIC_TEST_MKT_SERVICE_PRIVATE_KEY;






task("DeployCountsCredit", "Deploy Counts contract")
  .addPositionalParam("revenueWallet")
  .addPositionalParam("registryAddress")
  .addPositionalParam("poolAddress")
  .addPositionalParam("usdcAddress")
  .addPositionalParam("mktAdminAddress")
  .addPositionalParam("slotId")
  .addPositionalParam("name")
  .addPositionalParam("symbol")
  .addPositionalParam("baseuri")
  .addPositionalParam("contractDescription")
  .addPositionalParam("contractImage")
  .addPositionalParam("decimals")
  .setAction(async (args, hre) => {
    // 1. Get ethers from the Hardhat Runtime Environment (hre)
    const { ethers } = hre;

    const CountsCreditContract = await ethers.getContractFactory("CountsCredit");

    // 2. Deploy
    const credit = await CountsCreditContract.deploy(
      args.revenueWallet,
      args.registryAddress,
      args.poolAddress,
      args.usdcAddress,
      args.mktAdminAddress,
      args.slotId,
      args.name,
      args.symbol,
      args.baseuri,
      args.contractDescription,
      args.contractImage,
      args.decimals
    );

    // 3. Wait for deployment (Ethers v6 syntax)
    // If this fails with "credit.waitForDeployment is not a function", 
    // switch back to: await credit.deployed();
    await credit.waitForDeployment(); 

    // 4. Get Address and Transaction Hash (Ethers v6 syntax)
    const contractAddress = await credit.getAddress();
    const hashOfTx = credit.deploymentTransaction().hash;
    
    // 5. Get Receipt
    // In Hardhat tasks, credit.deploymentTransaction().wait() is usually sufficient
    const tx_receipt = await credit.deploymentTransaction().wait();

    // 6. Output JSON
    console.log(JSON.stringify({
        contract_address: contractAddress, 
        tx_receipt: tx_receipt, 
        tx_hash: hashOfTx
    }));
  });