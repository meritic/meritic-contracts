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






task("DeployCashCredit", "Deploy Cash contract")
  .addPositionalParam("revenueWallet")
  .addPositionalParam("registryAddress")
  .addPositionalParam("poolAddress")
  .addPositionalParam("underlyingValueAddress")
  .addPositionalParam("mktAdminAddress")
  .addPositionalParam("slotId")
  .addPositionalParam("name")
  .addPositionalParam("symbol")
  .addPositionalParam("baseuri")
  .addPositionalParam("contractDescription")
  .addPositionalParam("contractImage")
  .addPositionalParam("valueToken")
  .addPositionalParam("decimals")
  .setAction(async (args) => {




    const CashCreditContract = await ethers.getContractFactory("CashCredit");
	const credit = await CashCreditContract.deploy(
											args.revenueWallet,
											args.registryAddress,
											args.poolAddress,
											args.underlyingValueAddress,
											args.mktAdminAddress,
											args.slotId,
											args.name,
											args.symbol,
											args.baseuri,
											args.contractDescription,
											args.contractImage,
											args.valueToken,
											args.decimals);
	const hashOfTx = credit.deployTransaction.hash	
   	await credit.deployed();
   	

  	
    let tx_receipt = await credit.provider.getTransactionReceipt(hashOfTx);
  

    console.log(JSON.stringify({contract_address: credit.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));

  });
