const { task }  = require('hardhat/config');




// npx hardhat --network "polygon_mumbai" DeploySlotRegistry "0xB9441B7BC507136A7Bf0f130e58C3f810d1Dc090" “SlotRegistry” "SREG0" "baseuri" "contract desc" "image" 6


task("DeployPool", "Deploy Pool contract")
	.addPositionalParam("registryContractAddress")
	//.addPositionalParam("mktAdminAddress")
	//.addPositionalParam("valueCurrency")
	.addPositionalParam("name")
	.addPositionalParam("symbol")
	.addPositionalParam("baseUri")
	.addPositionalParam("contractDescription")
	.addPositionalParam("contractImage")
	.addPositionalParam("decimals")
	.setAction(async (args) => {

    const Pool = await ethers.getContractFactory("Pool");
    const pool = await Pool.deploy(	args.registryContractAddress,
    											//args.valueCurrency,
												args.name,
												args.symbol,
												args.baseUri,
												args.contractDescription,
												args.contractImage,
												args.decimals )		
    await pool.deployed();
    const hashOfTx = pool.deployTransaction.hash;	
    
    let tx_receipt = await pool.provider.getTransactionReceipt(hashOfTx);
    
    console.log(JSON.stringify({contract_address: pool.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));
    
  });
