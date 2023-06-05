//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";



contract SlotRegistry {

    mapping (uint256 => string) private _registry;    
    mapping (uint256 => string) private _name;    
    mapping (uint256 => string) private _description;
    
    
    function addSlot(uint256 slotId, string memory slotName_,  string memory slotURI_, string memory description_) external returns (bool){
        require(!exists(slotId), "Slot already registered");
        _registry[slotId] = slotURI_;
        _description[slotId] = description_;
        _name[slotId] = slotName_;
        return true;
    }
    
    function slotName(uint256 slotId_) external view returns (string memory) {
        require(exists(slotId_), "Slot is not registered");
        return _name[slotId_];
    }
    
    
    
    function slotDescription (uint256 slotId_) external view returns (string memory) {
        require(exists(slotId_), "Slot is not registered");
        return _description[slotId_];
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