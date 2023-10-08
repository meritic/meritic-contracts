
//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


import "@solvprotocol/erc-3525/periphery/ERC3525MetadataDescriptor.sol";
import "./SlotRegistry.sol";
//import "./Service.sol";






contract ServiceMetadataDescriptor is ERC3525MetadataDescriptor {
    
    
  using Strings for uint256;
    
    SlotRegistry sr;
    
    string private _baseURI;
    string private _contractDesc;
    string private contractImage;
    
    mapping (uint256 => string) private tokenDesc;   
    mapping (uint256 => string) private tokenImage;  
    mapping (uint256 => string) private tokenUUID;
    mapping (uint256 => string) private tokenProperty; 
    
    
    
    
    constructor(string memory baseURI_, string memory contractDescription_, 
        				string memory contractImage_, address slotRegistry_) ERC3525MetadataDescriptor() {
		_baseURI = baseURI_;
		_contractDesc = contractDescription_;
		contractImage = contractImage_;
		sr = SlotRegistry(slotRegistry_);
    }
    
    
    function baseURI() external view returns (string memory) {
        return _baseURI;
    }
    
    
    
    /*function constructTokenURI(uint256 tokenId_) external view override returns (string memory) {
        IERC3525Metadata erc3525 = IERC3525Metadata(msg.sender);
        return 
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                        
                            '{"name":"',
                            _tokenName(tokenId_),
                            '","description":"',
                            _tokenDescription(tokenId_),
                            '","image":"',
                            _tokenImage(tokenId_),
                            '","balance":"',
                            erc3525.balanceOf(tokenId_).toString(),
                            '","slot":"',
                            erc3525.slotOf(tokenId_).toString(),
                            '","properties":',
                            _tokenProperties(tokenId_),
                            "}"
                         
                        )
                    )
                )
            );
    }*/
    
	/*function constructTokenURI(uint256 tokenId_, uint256 balance_) external view  returns (string memory) {
        IERC3525Metadata erc3525 = IERC3525Metadata(msg.sender);
        // erc3525.balanceOf(tokenId_).toString(),
        return 
            string(
                abi.encodePacked(
            
                    '{"name":"',
                    _tokenName(tokenId_),
                    '","description":"',
                    _tokenDescription(tokenId_),
                    '","image":"',
                    _tokenImage(tokenId_),
                    '","balance":"',
                    balance_.toString(),
                    '","slot":"',
                    erc3525.slotOf(tokenId_).toString(),
                    '","properties":"',
                    _tokenProperties(tokenId_),
                    '"}'
           
                )
            );
    }*/
    
    
    
    
    /*function constructContractURI() external view  returns (string memory) {
        IERC3525Metadata erc3525 = IERC3525Metadata(msg.sender);
        return 
            string(
                   
                    abi.encodePacked(
                        '{"name":"', 
                        erc3525.name(),
                        '","description":"',
                        _contractDescription(),
                        '","image":"',
                        _contractImage(),
                        '","valueDecimals":"', 
                        uint256(erc3525.valueDecimals()).toString(),
                        '"}'
                    )
                   
                
            );
    }*/
    
    
    function setTokenUUID(uint256 tokenId_, string memory uuid_) external {
        tokenUUID[tokenId_] = uuid_;
    }
    

    
    function getTokenUUID(uint256 tokenId_) view external returns (string memory){
        return tokenUUID[tokenId_];
    }
    
    function getTokenDescription(uint256 tokenId_) view external returns (string memory){
        return tokenDesc[tokenId_];
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
    
    
    function getTokenImage(uint256 tokenId_) view external returns (string memory){
        return tokenImage[tokenId_];
    }
    
    
    
    function setTokenProperty(uint256 tokenId_, string memory jsonString_) external {
        tokenProperty[tokenId_] = jsonString_;
    }
    
    function _tokenDescription(uint256 tokenId_) internal view virtual override returns(string memory) {
        return tokenDesc[tokenId_];
    }
    
    
    
    function _tokenProperties(uint256 tokenId_) internal view virtual override returns (string memory) {
        //return string(abi.encodePacked("{}"));
        return string(abi.encodePacked('{"properties_uri":', '"', _baseURI, 'contract/', Strings.toHexString(msg.sender), 
        				'/token/', tokenUUID[tokenId_], '/properties.json', '"}'));
    }
    
    
    
    
}