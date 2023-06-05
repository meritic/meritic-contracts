
const { task }  = require('hardhat/config');


task("DeployTokenSwap", "Deploy Uniswap2Router TokenSwap")
  .setAction(async (args) => {

    const TokenSwap = await ethers.getContractFactory("TokenSwap");
    const tokenswap = await TokenSwap.deploy(process.env.UNISWAP_SWAPROUTER_CONTRACT_ADDRESS);	
    await tokenswap.deployed();
    const hashOfTx = tokenswap.deployTransaction.hash;	
    
    let tx_receipt = await tokenswap.provider.getTransactionReceipt(hashOfTx);
    console.log(JSON.stringify({contract_address: tokenswap.address, tx_receipt: tx_receipt, tx_hash: hashOfTx}));
    
  });
