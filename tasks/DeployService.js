//import { task } from "hardhat/config";
const { task }  = require('hardhat/config');
//const { ethers } = require('ethers');
//const ethers = require('hardhat');
//const { config } =  require('dotenv');

const registryAddress = process.env.SLOT_REGISTRY_CONTRACT_ADDRESS;
const WUSDCContractAddress = process.env.WUSDC_CONTRACT_ADDRESS;

const MERITIC_TEST_MKT_SERVICE_ADDRESS = process.env.MERITIC_TEST_MKT_SERVICE_ADDRESS;
const MERITIC_TEST_MKT_SERVICE_PRIVATE_KEY = process.env.MERITIC_TEST_MKT_SERVICE_PRIVATE_KEY;



//const NETWORK_URL = `https://rpc-mumbai.maticvigil.com/v1`;
//const provider = new ethers.providers.JsonRpcProvider(NETWORK_URL);
//const wallet = new ethers.Wallet(MERITIC_TEST_MKT_SERVICE_PRIVATE_KEY, provider);
//var signer =  provider.getSigner(wallet.address);





task("DeployService", "Deploy Service contract")
  .addPositionalParam("adminAddress")
  .addPositionalParam("mktAdminAddress")
  .addPositionalParam("slotRegistryAddress")
  .addPositionalParam("defaultSlot")
  .addPositionalParam("name")
  .addPositionalParam("symbol")
  //.addPositionalParam("decimals")
  .setAction(async (args) => {


    const ServiceToken = await ethers.getContractFactory("Service");


	
	const service = await ServiceToken.deploy(
											args.adminAddress,
											args.mktAdminAddress,
											args.slotRegistryAddress,
											args.defaultSlot,
											args.name,
											args.symbol
											/*args.contractImage,
											WUSDCContractAddress,
											parseInt(args.decimals)*/);
	const hashOfTx = service.deployTransaction.hash	
   	await service.deployed();
   	
   	
  
  	//var out = await mint_out.wait();
  	
    let tx_receipt = await service.provider.getTransactionReceipt(hashOfTx);
    //const logs = service.events.MetadataDescriptor.processReceipt(tx_receipt)
   
    
    console.log(JSON.stringify({contract_address: service.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));

    
  });
