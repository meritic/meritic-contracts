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

const NETWORK_URL = `https://rpc-mumbai.maticvigil.com/v1`;






task("DeployCashCredit", "Deploy Cash contract")
  .addPositionalParam("revenueWallet")
  .addPositionalParam("adminWallet")
  .addPositionalParam("slotId")
  .addPositionalParam("name")
  .addPositionalParam("symbol")
  .addPositionalParam("baseuri")
  .addPositionalParam("contractDescription")
  .addPositionalParam("contractImage")
  .addPositionalParam("valueToken")
  .addPositionalParam("decimals")
  .setAction(async (args) => {




    const CashCreditContract = await ethers.getContractFactory("SpendCredit");
	const service = await CashCreditContract.deploy(
											args.revenueWallet,
											args.adminWallet,
											registryAddress,
											WUSDCContractAddress,
											MERITIC_TEST_MKT_SERVICE_ADDRESS,
											args.slotId,
											args.name,
											args.symbol,
											args.baseuri,
											args.contractDescription,
											args.contractImage,
											args.valueToken,
											args.decimals);
	const hashOfTx = service.deployTransaction.hash	
   	await service.deployed();
   	

  	
    let tx_receipt = await service.provider.getTransactionReceipt(hashOfTx);
  

    console.log(JSON.stringify({contract_address: service.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));

  });
