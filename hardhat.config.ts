import dotenv from 'dotenv';
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";





const config: HardhatUserConfig = {
  solidity: "0.8.17", 
  defaultNetwork: "polygon_mumbai",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    polygon_mumbai: {
		url: "https://rpc-mumbai.maticvigil.com/",
		accounts: process.env.METAMASK_PRIVATE_KEY
	}
  },
  etherscan: {
	  apiKey: process.env.POLYGONSCAN_API_KEY
  }
};

export default config;
