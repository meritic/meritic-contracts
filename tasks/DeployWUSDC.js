
const { task }  = require('hardhat/config');


const MERITIC_TEST_MKT_SERVICE_ADDRESS = process.env.MERITIC_TEST_MKT_SERVICE_ADDRESS;
const UNDERLYING_TEST_USDC = process.env.UNDERLYING_TEST_USDC;

task("DeployWUSDC", "Deploy WUSDC contract")
  .setAction(async (args) => {

    const WUSDC = await ethers.getContractFactory("WUSDC");
    const wusdc = await WUSDC.deploy(UNDERLYING_TEST_USDC, MERITIC_TEST_MKT_SERVICE_ADDRESS);	
    await wusdc.deployed();
    const hashOfTx = wusdc.deployTransaction.hash;	
    
    let tx_receipt = await wusdc.provider.getTransactionReceipt(hashOfTx);
    console.log(JSON.stringify({contract_address: wusdc.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));
    
  });
