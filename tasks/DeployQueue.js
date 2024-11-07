
const { task }  = require('hardhat/config');


task("DeployQueue", "Deploy queue contract")
	.setAction(async () => {

    const Queue = await ethers.getContractFactory('Queue');

    const queue = await Queue.deploy();	
    await queue.deployed();
    const hashOfTx = queue.deployTransaction.hash;	
    
    let tx_receipt = await queue.provider.getTransactionReceipt(hashOfTx);
    console.log(JSON.stringify({contract_address: queue.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));
    
  });
