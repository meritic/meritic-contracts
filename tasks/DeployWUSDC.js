
const { task }  = require('hardhat/config');


// const MERITIC_TEST_MKT_SERVICE_ADDRESS = process.env.MERITIC_TEST_MKT_SERVICE_ADDRESS;
// const UNDERLYING_USDC = process.env.UNDERLYING_USDC;

task("DeployWUSDC", "Deploy WUSDC contract")
  .addParam("admin", "The market admin address")
  .setAction(async (args) => {

    const WUSDC = await ethers.getContractFactory("WUSDC");
	const wusdc = await WUSDC.deploy(args.admin);
    await wusdc.deployed();
	console.log("WUSDC deployed to:", wusdc.target);
    const hashOfTx = wusdc.deployTransaction.hash;	
   
    let tx_receipt = await wusdc.provider.getTransactionReceipt(hashOfTx);
    console.log(JSON.stringify({contract_address: wusdc.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));
    
  });
