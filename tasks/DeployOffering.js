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







				

task("DeployOffering", "Deploy Offering contract")
  .addPositionalParam("revenueWallet")
  .addPositionalParam("registryAddress")
  .addPositionalParam("poolAddress")
  .addPositionalParam("underlyingValueAddress")
  .addPositionalParam("name")
  .addPositionalParam("symbol")
  .addPositionalParam("baseuri")
  .addPositionalParam("contractDescription")
  .addPositionalParam("contractImage")
  .addPositionalParam("decimals")
  .setAction(async (args) => {




    const OffringContract = await ethers.getContractFactory("Offering");
	const ofContract = await OffringContract.deploy(
											args.revenueWallet,
											args.registryAddress,
											args.poolAddress,
											args.underlyingValueAddress,
											args.name,
											args.symbol,
											args.baseuri,
											args.contractDescription,
											args.contractImage,
											args.decimals);
	const hashOfTx = ofContract.deployTransaction.hash	
   	await ofContract.deployed();
   	

  	
    let tx_receipt = await ofContract.provider.getTransactionReceipt(hashOfTx);
  

    console.log(JSON.stringify({contract_address: ofContract.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));

  });
