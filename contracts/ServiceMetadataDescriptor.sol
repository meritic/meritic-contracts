
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


import "@solvprotocol/erc-3525/periphery/ERC3525MetadataDescriptor.sol";
import "./SlotRegistry.sol";
//import "./Service.sol";






contract ServiceMetadataDescriptor is ERC3525MetadataDescriptor {
    
    
  
    
    SlotRegistry sr;
    
    string private _baseURI;
    string private _contractDesc;
    string private contractImage;
    
    mapping (uint256 => string) private tokenDesc;   
    mapping (uint256 => string) private tokenImage;  
    mapping(uint256 => string) private tokenUUID;
    
    
    
    
    constructor(string memory baseURI_, string memory contractDescription_, 
        				string memory contractImage_, address slotRegistry_) ERC3525MetadataDescriptor() {
		_baseURI = baseURI_;
		_contractDesc = contractDescription_;
		contractImage = contractImage_;
		sr = SlotRegistry(slotRegistry_);
    }
    
    function setTokenUUID(uint256 tokenId_, string memory uuid_) external {
        tokenUUID[tokenId_] = uuid_;
    }
    

    
    
    
    function _contractDescription() internal view virtual override returns (string memory) {
        return _contractDesc; 
    }
    
    
    
    function _contractImage() internal view virtual override returns (bytes memory) {
        return abi.encodePacked(_baseURI, "contract/", Strings.toHexString(msg.sender), "/", contractImage);
    }
    
    function _tokenImage(uint256 tokenId_) internal view override returns (bytes memory) {
        
        return abi.encodePacked(_baseURI, "/contract/", Strings.toHexString(address(this)), "/token/", tokenUUID[tokenId_], "/", tokenImage[tokenId_]);
    }
    
    
    function _slotName(uint256 slot_) internal view virtual override returns (string memory) {
		return sr.slotName(slot_);
    }
 
    
    function _slotDescription(uint256 slot_) internal view override returns (string memory) {
        return sr.slotDescription(slot_);
    }
    

    function _slotImage(uint256 slot_) internal view virtual override returns (bytes memory) {
        return abi.encodePacked(sr.slotURI(slot_), "/image");
    }
    
    function _slotProperties(uint256 slot_) internal view virtual override returns (string memory) {
        return string(abi.encodePacked(sr.slotURI(slot_), "/properties.json"));
    }
    
    
    function setBaseURI(string memory uri_) external {
        _baseURI = uri_;
    }
    
    function setTokenDescription(uint256 tokenId_, string memory description_) external  {
        tokenDesc[tokenId_] = description_;
    }
    
    
    function setTokenImage(uint256 tokenId_, string memory imgname_) external {
        tokenImage[tokenId_] = imgname_;
    }
    
    
    
    function _tokenDescription(uint256 tokenId_) internal view virtual override returns(string memory) {
        return tokenDesc[tokenId_];
    }
    
    
    
    
    function _tokenProperties(uint256 tokenId_) internal view virtual override returns (string memory) {
        return string(abi.encodePacked("{properties_uri", _baseURI, "contract/", Strings.toHexString(msg.sender), 
        				"/token/", tokenUUID[tokenId_], "/properties.json", "}"));
    }
    
    
}