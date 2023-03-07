// import dotenv from 'dotenv';
import { HardhatUserConfig } from "hardhat/config";
//import type { HardhatUserConfig } from "hardhat/types";
import "@nomicfoundation/hardhat-toolbox";


const config: HardhatUserConfig = {
  solidity: {
	  version: "0.8.17",
	  settings: {
		  optimizer: {
			  enabled: true,
			  runs: 200
		  }
	   }
  },
  defaultNetwork: "hardhat",
  networks: {
	  hardhat: {
	    forking: {
	      url: "https://eth-mainnet.alchemyapi.io/v2/l2oG-ebJu5YPgFRjAU8EemqamliNp1p6",
	      blockNumber: 14390000
	    }
	 }
  }
};

export default config;
