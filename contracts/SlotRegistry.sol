//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";



contract SlotRegistry {
    //using Strings for uint256;

    
    mapping (uint256 => string) private _registry;    
    
    function addSlot(uint256 slotId, string memory slotURI) public returns (bool){
        require(!exists(slotId), "Slot already registered");
        _registry[slotId] = slotURI;
        return true;
    }
    
    
    function exists(uint256 slotId) public view returns (bool){
        return bytes(_registry[slotId]).length > 0;
    }
    
    
    function slotURI(uint256 slotId_) public view returns (string memory) {
        require(exists(slotId_), "Slot is not registered");
        //return string(abi.encodePacked(baseURI, "slot/", slot_.toString())); 
        return _registry[slotId_];
    }

}