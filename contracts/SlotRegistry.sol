//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@solvprotocol/erc-3525/ERC3525.sol";
import "./ServiceMetadataDescriptor.sol";	
import "./Service.sol";


contract SlotRegistry is ERC3525 {
	
	//bytes32 public constant NETWORK_TOKEN_ADMIN_ROLE = keccak256("NETWORK_TOKEN_ADMIN_ROLE");
	
	//mapping (uint256 => string) private _registry;  
    //mapping (uint256 => string) private _name;    
    //mapping (uint256 => string) private _description;
    
    enum SlotType {contract_, network_, networkRevShare_ }
    enum CreditType {time_, cash_, items_, priority_}
    
    struct Slot {
    	address creator;
        uint256 slotId;
        string name;
        string description;
        string slotURI;
        SlotType slotType;
        address[] contracts;
        
    }

	mapping(address => CreditType) internal _contractType;
    
    
    mapping(uint256 => Slot) private _registry;  
    // mapping(uint256 => uint256) private _slotOfToken;
    mapping(uint256 => address) private _contractOfToken;
    //mapping(address => uint256) private _contractSlot;
    
    mapping(uint256 => uint256) private _tokenDiscount;
    mapping(uint256 => uint256) private _tokenTVRate;
    
    mapping(uint256 => mapping(address => bool)) private _inSlotNetwork;
    mapping(uint256 => mapping(address => bool)) private _isSlotAdmin;
  
    
    string private _baseuri;    
    
    uint256 internal _discountDecimals = 18;
    
    event MetadataDescriptor(address  contractAddress);
    event NewSlot(uint256 slotId, string slotName);
    
    
    constructor(string memory name_, 
        		string memory symbol_, 
        		string memory baseuri_,
        		string memory contractDescription_,
        		string memory contractImage_,
        		uint8 decimals_) ERC3525(name_, symbol_, decimals_) {
        		   
  		_baseuri = baseuri_;
        metadataDescriptor = new ServiceMetadataDescriptor(_baseuri, contractDescription_, contractImage_, address(this));
        emit MetadataDescriptor(address(metadataDescriptor));
        
    }
    
    
    
    
    
    
    function registerContract(address adminAddress_, uint256 slot_, CreditType type_) external {
        require(_isSlotAdmin[slot_][adminAddress_], "Contract admin is not authorized to register to this slot");
        _registry[slot_].contracts.push(msg.sender);
        _contractType[msg.sender] = type_;
        _inSlotNetwork[slot_][msg.sender] = true;
        
        /*if(_registry[slot_].slotType == SlotType.contract_){
            _contractSlot[msg.sender] = slot_;
        }*/
        
    }
    
    
    
    function registerSlot(uint256 slotId_, string memory slotName_,  string memory slotURI_, string memory description_, SlotType type_) external returns (bool){
        require(!exists(slotId_), "Slot already registered");


    
        Slot memory _newSlot = Slot({creator: msg.sender, slotId: slotId_, name: slotName_, description: description_, slotURI: slotURI_, slotType: type_,  contracts: new address[](0)});
        _registry[slotId_] = _newSlot;
        _isSlotAdmin[slotId_][msg.sender] = (_registry[slotId_].slotId == slotId_);
        
        emit NewSlot(_registry[slotId_].slotId, _registry[slotId_].name);
        
        return _isSlotAdmin[slotId_][msg.sender];
    }
    
    
    
    function approveContractForSlot(address contract_, uint256 slotId_) public  {
        require(_isSlotAdmin[slotId_][msg.sender], "Sender not authorized to approve on this slot");
        
        //uint256 defaultSlot = _contractSlot[contract_];
        address contractAdmin_ = Service(contract_).contractAdmin();
        _isSlotAdmin[slotId_][contractAdmin_] = true;
        
        // emit event notfying approvial
    }
    
    
    function isNetworkToken(uint256 tokenId_) external view returns (bool){
        return ERC3525._exists(tokenId_);
    }
    
    function slotName(uint256 slotId_) external view returns (string memory) {
        require(exists(slotId_), "Slot is not registered");
        return _registry[slotId_].name;
    }
    
    
    
    function slotDescription (uint256 slotId_) external view returns (string memory) {
        require(exists(slotId_), "Slot is not registered");
        return _registry[slotId_].description;
    }
    
    function exists(uint256 slotId) public view returns (bool){
        return bytes(_registry[slotId].name).length > 0;
    }
    
    
    function slotURI(uint256 slotId_) public view override returns (string memory) {
        require(exists(slotId_), "Slot is not registered");
        //return string(abi.encodePacked(baseURI, "slot/", slot_.toString())); 
        return _registry[slotId_].slotURI;
    }
    
    
    
    function mint(address owner_, 
        			uint256 slot_, 
        			uint256 value_
    ) external virtual returns (uint256) {
        require(_inSlotNetwork[slot_][msg.sender], "Sender not authorized to mint to slot");
        uint256 tokenId = ERC3525._mint(owner_, slot_, value_);
        _contractOfToken[tokenId] = msg.sender;
        return tokenId;
    }
    
    
    
    function mintWithDiscount(address owner_, uint256 slot_, uint256 value_, uint256 adjDiscountBasisPts_) external returns (uint256) {
        require(_inSlotNetwork[slot_][msg.sender], "Sender not authorized to mint to slot");
        uint256 tokenId = ERC3525._mint(owner_, slot_, value_);
        _contractOfToken[tokenId] = msg.sender;

        _tokenDiscount[tokenId] = adjDiscountBasisPts_;
        
        return tokenId;
    }
    
    
    
    
    
    function mintWithTVRate(address owner_, uint256 slot_, uint256 value_, uint256 adjTVRate_) public returns (uint256) {
        
        uint256 tokenId = ERC3525._createOriginalTokenId();
        ERC3525._mint(owner_, tokenId, slot_, value_);
        _tokenTVRate[tokenId] = adjTVRate_;
        
        return tokenId;
    }
    
    
    
    
    
    
    

    
    function contractOf(uint256 networkTokenId_) external view returns (address){
        ERC3525._requireMinted(networkTokenId_);
        return _contractOfToken[networkTokenId_];
    }
    
    
    function approve(uint256 tokenId_, address to_, uint256 value_) public payable virtual override {
        ERC3525._requireMinted(tokenId_);
		ERC3525.approve(tokenId_, to_, value_);
    }
    
    
    
    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override returns (uint256) {
        ERC3525._requireMinted(fromTokenId_);
    	uint256 newTokenId =  ERC3525.transferFrom(fromTokenId_, to_, value_);
  
    	return newTokenId;
    }
    
    
    function _cashValueTransfer(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) internal {
        uint256 tenKBasisPts = 10000;
        uint256 toTokenValue = super.balanceOf(toTokenId_);
        
        uint256 discount;
        
        if(_tokenDiscount[fromTokenId_] != _tokenDiscount[toTokenId_]){
            discount = tenKBasisPts * (10 ** _discountDecimals) - ((tenKBasisPts *  (10 ** _discountDecimals) - _tokenDiscount[fromTokenId_]) * value_ + (tenKBasisPts * (10 ** _discountDecimals) - _tokenDiscount[toTokenId_]) * toTokenValue) / (value_ + toTokenValue);
        }else{
            discount = _tokenDiscount[toTokenId_];
        }
        
        _tokenDiscount[toTokenId_] = discount;
        
        super.transferFrom(fromTokenId_, toTokenId_, value_);
    }
    
    
    
    
    function _timeValueTransfer(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) internal {
        uint256 toTokenValue = ERC3525.balanceOf(toTokenId_);
  	    
  	    _tokenTVRate[toTokenId_] = (_tokenTVRate[fromTokenId_] * value_ + _tokenTVRate[toTokenId_] * toTokenValue) / (value_ + toTokenValue);
        
        super.transferFrom(fromTokenId_, toTokenId_, value_);
    }
    
    
    
    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable virtual override {
        ERC3525._requireMinted(fromTokenId_);
	    ERC3525._requireMinted(toTokenId_);
	    
	    uint256 slotId = ERC3525.slotOf(fromTokenId_);
	    uint256 toSlotId = ERC3525.slotOf(toTokenId_);
	    
	    require(slotId == toSlotId, 'SlotRegistry: transfer to token with different slot.');
	    
	    CreditType creditType = _contractType[msg.sender];
	    CreditType toType = _contractType[_contractOfToken[toTokenId_]];
	    
	    require(creditType == toType, 'SlotRegistry: Cannot transfer between tokens holding different types of credit.');
	    require(creditType != CreditType.time_, 'SlotRegistry: Network value transfer not allowed for priority tokens');
	    
	    
	    if(creditType == CreditType.cash_){
	        _cashValueTransfer(fromTokenId_, toTokenId_, value_);
	    }else if(creditType == CreditType.time_){
	        _timeValueTransfer(fromTokenId_, toTokenId_, value_);
	    }else if(creditType == CreditType.items_){
	        ERC3525.transferFrom(fromTokenId_, toTokenId_, value_);
	    }
	    
    }
    
    
    
    
    
    function tokenDiscount(uint256 toTokenId_) public view returns (uint256){
        ERC3525._requireMinted(toTokenId_);
        
	    return _tokenDiscount[toTokenId_];
	}
	
	function timeValueRate(uint256 toTokenId_) public view returns (uint256){
	    return _tokenTVRate[toTokenId_];
	}

}