//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;




interface Underlying {
	
	function redeem(address to_, uint256 slotId_, uint256 amount_) external;
	
	function mint(address to_, uint256 slotId_, uint256 amount_) external;
	
	function transfer(address to_, uint256 amount_) external returns (bool);

}