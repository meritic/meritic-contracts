const { task }  = require('hardhat/config');





        		
task("DeploySlotRegistry", "Deploy Slot Registry contract")
	.addPositionalParam("mktAdminAddress")
	.addPositionalParam("name")
	.addPositionalParam("symbol")
	.addPositionalParam("baseUri")
	.addPositionalParam("contractDescription")
	.addPositionalParam("contractImage")
	.addPositionalParam("decimals")
	.setAction(async (args) => {

    const SlotRegistry = await ethers.getContractFactory("SlotRegistry");
    const registry = await SlotRegistry.deploy(	args.mktAdminAddress,
												args.name,
												args.symbol,
												args.baseUri,
												args.contractDescription,
												args.contractImage,
												args.decimals )		
    await registry.deployed();
    const hashOfTx = registry.deployTransaction.hash;	
    
    let tx_receipt = await registry.provider.getTransactionReceipt(hashOfTx);
    
    console.log(JSON.stringify({contract_address: registry.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));
    
  });
