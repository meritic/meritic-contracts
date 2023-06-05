
const { task }  = require('hardhat/config');


task("DeployWUSDC", "Deploy WUSDC contract")
  .setAction(async (args) => {

    const WUSDC = await ethers.getContractFactory("WUSDC");
    const wusdc = await WUSDC.deploy();	
    await wusdc.deployed();
    const hashOfTx = wusdc.deployTransaction.hash;	
    
    let tx_receipt = await wusdc.provider.getTransactionReceipt(hashOfTx);
    console.log(JSON.stringify({contract_address: wusdc.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));
    
  });
