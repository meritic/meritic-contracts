//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;




interface Underlying {
	
	function mint(address to_, uint256 slotId_, uint256 amount_) external;
	
	function burn(address from, uint256 slotId_, uint256 amount) external;
	
	function transfer(address to_, uint256 amount_) external returns (bool);

}