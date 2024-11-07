//SPDX-License-Identifier: 	BUSL-1.1

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Strings.sol";




contract Util {
    

	function strToLower(string memory str) public view returns (string memory) {
		bytes memory bStr = bytes(str);
		bytes memory bLower = new bytes(bStr.length);
		for (uint i = 0; i < bStr.length; i++) {
			if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
				bLower[i] = bytes1(uint8(bStr[i]) + 32);
			} else {
				bLower[i] = bStr[i];
			}
		}
		return string(bLower);
	}
	

}
