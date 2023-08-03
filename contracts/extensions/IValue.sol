//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;




interface IValue {
	
	function redeem(address to, uint256 amount) external payable;
	
	function mint(address to, uint256 amount) external payable;
	
	function transfer(address to, uint256 amount) external returns (bool);

}