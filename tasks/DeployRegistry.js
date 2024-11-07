const { task }  = require('hardhat/config');


 		
task("DeployRegistry", "Deploy Registry contract")
	.addPositionalParam("utilContractAddress")
	.setAction(async (args) => {

    const Registry = await ethers.getContractFactory("Registry");
    const registry = await Registry.deploy(args.utilContractAddress);
    await registry.deployed();
    const hashOfTx = registry.deployTransaction.hash;	
    
    let tx_receipt = await registry.provider.getTransactionReceipt(hashOfTx);
    
    console.log(JSON.stringify({contract_address: registry.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));
    
  });
