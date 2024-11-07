
const { task }  = require('hardhat/config');


task("DeployUtil", "Deploy util contract")
	.setAction(async () => {

    const Util = await ethers.getContractFactory('Util');

    const util = await Util.deploy();	
    await util.deployed();
    const hashOfTx = util.deployTransaction.hash;	
    
    let tx_receipt = await util.provider.getTransactionReceipt(hashOfTx);
    console.log(JSON.stringify({contract_address: util.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));
    
  });
