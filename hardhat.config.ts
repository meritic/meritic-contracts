// import dotenv from 'dotenv';
import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();
//import { HardhatUserConfig } from "hardhat/config";
import type { HardhatUserConfig } from "hardhat/types";
import "@nomiclabs/hardhat-truffle5";
import "@nomiclabs/hardhat-ethers";
import "@nomicfoundation/hardhat-toolbox";
import "./tasks/DeploySlotRegistry.js";

import "./tasks/DeployService.js";
import "./tasks/DeploySlotRegistry.js";
import "./tasks/DeployTimeCredit.js";
import "./tasks/DeployCashCredit.js";
import "./tasks/DeployWUSDC.js";
import "./tasks/DeployTestUSDC.js";
import "./tasks/DeployTokenSwap.js";


const privatekey = process.env.MERITIC_TEST_MKT_SERVICE_PRIVATE_KEY;

const config: HardhatUserConfig = {
  solidity: {
	  version: "0.8.17",
	  settings: {
		  optimizer: {
			  enabled: true,
			  runs: 200
		  },
		  viaIR: true,
	   }
  },
  defaultNetwork: "hardhat", 
  //defaultNetwork: "polygon_mumbai",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    polygon_mumbai: {
		chainId: 80001,
		url: "https://rpc-mumbai.maticvigil.com",
		accounts: [ privatekey ],
		allowUnlimitedContractSize: true
	}
  },
  etherscan: {
	  apiKey: process.env.POLYGONSCAN_API_KEY
  }
};

export default config;
