// import dotenv from 'dotenv';
import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();
//import { HardhatUserConfig } from "hardhat/config";
import type { HardhatUserConfig } from "hardhat/types";
import "@nomiclabs/hardhat-truffle5";
import "@nomicfoundation/hardhat-toolbox";
import "./tasks/DeployService.js";
import "./tasks/DeployWUSDC.js";
import "./tasks/DeployTestUSDC.js";
import "./tasks/DeploySlotRegistry.js";
import "./tasks/DeployTokenSwap.js";


const privatekey = process.env.MERITIC_TEST_MKT_SERVICE_PRIVATE_KEY;

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
  //defaultNetwork: "polygon_mumbai",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    polygon_mumbai: {
		url: "https://rpc-mumbai.maticvigil.com/",
		accounts: [ privatekey ],
		allowUnlimitedContractSize: true
	}
  },
  etherscan: {
	  apiKey: process.env.POLYGONSCAN_API_KEY
  }
};

export default config;
