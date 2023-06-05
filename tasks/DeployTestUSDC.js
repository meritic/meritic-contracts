
const { task }  = require('hardhat/config');


task("DeployTestUSDC", "Deploy Test USDC contract")
  .setAction(async (args) => {

    const TestUSDC = await ethers.getContractFactory("TestUSDC");
    const testusdc = await TestUSDC.deploy();	
    await testusdc.deployed();
    const hashOfTx = testusdc.deployTransaction.hash;	
    
    let tx_receipt = await testusdc.provider.getTransactionReceipt(hashOfTx);
    console.log(JSON.stringify({contract_address: testusdc.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));
    
  });
