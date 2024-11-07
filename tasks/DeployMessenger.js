

const { task }  = require('hardhat/config');


task("DeployMessenger", "Deploy messenger contract")
	.addPositionalParam("registryContractAddress")
	.addPositionalParam("poolContractAddress")
	.addPositionalParam("utilContractAddress")
	.addPositionalParam("queueContractAddress")
	.setAction(async (args) => {

    const Messenger = await ethers.getContractFactory('Messenger');

    const messenger = await Messenger.deploy(
												args.registryContractAddress,
    											args.poolContractAddress,
    											args.utilContractAddress,
    											args.queueContractAddress
    										);	
    await messenger.deployed();
    const hashOfTx = messenger.deployTransaction.hash;	
    
    let tx_receipt = await messenger.provider.getTransactionReceipt(hashOfTx);
    console.log(JSON.stringify({contract_address: messenger.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));
    
  });
