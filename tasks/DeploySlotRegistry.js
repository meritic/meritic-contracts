const { task }  = require('hardhat/config');


task("DeploySlotRegistry", "Deploy Slot Registry contract")
  .setAction(async (args) => {

    const SlotRegistry = await ethers.getContractFactory("SlotRegistry");
    const registry = await SlotRegistry.deploy()		
    await registry.deployed();
    const hashOfTx = registry.deployTransaction.hash;	
    
    let tx_receipt = await registry.provider.getTransactionReceipt(hashOfTx);
    console.log(JSON.stringify({contract_address: registry.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));
    
  });
