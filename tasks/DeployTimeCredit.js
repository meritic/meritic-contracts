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


const getContractABI = async(contract) => {
  try {
	  const pathstr = `/meritic-contracts/artifacts/contracts/${contract}.sol/${contract}.json`;
	  const filepath = path.join(process.env.MERITIC_DIR, pathstr);
	  const file = fs.readFileSync(filepath, 'utf8');
	  const json = await JSON.parse(file);
	  const abi = json.abi;
	  
	  return abi;
  } catch (e) {
	  console.log(`e`, e);
  }
}





task("DeployTimeCredit", "Deploy Time contract")
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
  //.addPositionalParam("transfersAllowed")
  //.addPositionalParam("minAllowedValueTransfer")
  .addPositionalParam("dispTimeUnit")
  //.addPositionalParam("valueToken")
  //.addPositionalParam("moneyContractAddress")
  .addPositionalParam("decimals")
  .setAction(async (args) => {


    const TimeCreditContract = await ethers.getContractFactory("TimeCredit");
	const service = await TimeCreditContract.deploy(
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
											args.dispTimeUnit,
											args.decimals);
	const hashOfTx = service.deployTransaction.hash	
   	await service.deployed();
   	

  
  	//var out = await mint_out.wait();
  	
    let tx_receipt = await service.provider.getTransactionReceipt(hashOfTx);
    //const logs = service.events.MetadataDescriptor.processReceipt(tx_receipt)
  

    console.log(JSON.stringify({contract_address: service.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));

    
    
  });
