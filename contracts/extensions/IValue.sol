//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;




interface IValue {
    
    //function setUSDCContractAddress(address contract_) external; 
    
	function transfer(address from_, address to_, uint256 value_) external payable;
	
	function redeem(uint256 amount, address to) external payable;
	
	function mint(uint256 amount, address to) external payable;

}