//SPDX-License-Identifier: 	BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@solvprotocol/erc-3525/ERC3525.sol";
import "./ServiceMetadataDescriptor.sol";	
import "./Registry.sol";






contract Pool is ERC3525, AccessControl {
    
    
	// Tracks which Service Contract minted this token
    // This dictates where the underlying funds live
	mapping(uint256 => address) private _contractOfToken;
    
    mapping(uint256 => uint256) private _tokenValueRate;
	
    Registry internal _registry;
    
    uint256 internal _discountDecimals = 18;
    
	
	event MetadataDescriptor(address contractAddress);
    
    constructor(
        address regContract_,
        string memory name_, 
        string memory symbol_, 
        string memory baseuri_,
        string memory contractDescription_,
        string memory contractImage_,
        uint8 decimals_
    ) ERC3525(name_, symbol_, decimals_) {

  		_registry = Registry(regContract_); 
        // Note: Pool admin is usually the Mkt Admin, handled via setup in deployment script
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  		
        metadataDescriptor = new ServiceMetadataDescriptor(baseuri_, contractDescription_, contractImage_, address(this));
        emit MetadataDescriptor(address(metadataDescriptor));
    }
    
    
    modifier onlyRegisteredContract() {
        require(_registry.isRegisteredContract(msg.sender), "Pool: Caller not a registered service");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC3525, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    
    
    // --- MINTING LOGIC (Called by Service Contracts) ---
    
    /**
     * @notice Mints a standard token on the network.
     * @param owner_ The user receiving the token.
     * @param slot_ The slot ID.
     * @param value_ The value amount.
     */
    function mint(address owner_, uint256 slot_, uint256 value_) external onlyRegisteredContract returns (uint256) {
        uint256 tokenId = ERC3525._mint(owner_, slot_, value_);
        _contractOfToken[tokenId] = msg.sender;
        return tokenId;
    }
    
	/**
     * @notice Mints a token with a specific value rate.
     * Used by Cash, Count, and Time credits.
     */
    function mintWithValueRate(address owner_, uint256 slot_, uint256 value_, uint256 rate_) public onlyRegisteredContract returns (uint256) {
        uint256 tokenId = ERC3525._mint(owner_, slot_, value_);
        _contractOfToken[tokenId] = msg.sender;
        _tokenValueRate[tokenId] = rate_;
        return tokenId;
    }
    
    // --- GETTERS ---

    function isNetworkToken(uint256 tokenId_) external view returns (bool){
        return ERC3525._exists(tokenId_);
    }

    function contractOf(uint256 tokenId_) external view returns (address){
        ERC3525._requireMinted(tokenId_);
        return _contractOfToken[tokenId_];
    }
    
    function tokenValueRate(uint256 tokenId_) public view returns (uint256){
	    return _tokenValueRate[tokenId_];
	}
    
    // --- TRANSFERS & VALUE LOGIC ---
    
    function approve(uint256 tokenId_, address to_, uint256 value_) public payable virtual override {
        ERC3525._requireMinted(tokenId_);
		ERC3525.approve(tokenId_, to_, value_);
    }
    
    function transferFrom(uint256 fromTokenId_, address to_, uint256 value_) public payable virtual override returns (uint256) {
        ERC3525._requireMinted(fromTokenId_);
    	uint256 newTokenId = ERC3525.transferFrom(fromTokenId_, to_, value_);
        
        // Inherit properties from source
        _contractOfToken[newTokenId] = _contractOfToken[fromTokenId_];
        _tokenValueRate[newTokenId] = _tokenValueRate[fromTokenId_];
        
    	return newTokenId;
    }
    
 
   
    
    /**
     * @dev Internal logic to handle merging rates when moving Tokens.
     *      Used for Cash, Time, and Counts (Uniform Logic).
     */
    function _rateValueTransfer(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_) internal {
        uint256 toTokenValue = ERC3525.balanceOf(toTokenId_);
  	    
        // Weighted Average Rate Calculation
        // (OldRate * OldBal + TransferRate * TransferAmt) / NewTotalBal
  	    _tokenValueRate[toTokenId_] = (_tokenValueRate[fromTokenId_] * value_ + _tokenValueRate[toTokenId_] * toTokenValue) / (value_ + toTokenValue);
        
        super.transferFrom(fromTokenId_, toTokenId_, value_);
    }
    
    function transferFrom(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_) public payable virtual override {
        ERC3525._requireMinted(fromTokenId_);
	    ERC3525._requireMinted(toTokenId_);
	    
	    uint256 slotId = ERC3525.slotOf(fromTokenId_);
	    uint256 toSlotId = ERC3525.slotOf(toTokenId_);
	    
	    require(slotId == toSlotId, 'Pool: transfer to token with different slot.');
	
	    Registry.CreditType fromType = _registry.contractType(_contractOfToken[fromTokenId_]); 
	    Registry.CreditType toType = _registry.contractType(_contractOfToken[toTokenId_]);
	    
	    require(fromType == toType, 'Pool: Cannot transfer between different types of credit.');
	    
        // UNIFIED: Use _rateValueTransfer for ALL types (Cash, Time, Counts)
        // We deleted _cashValueTransfer because Cash now uses the Rate model too.
	    _rateValueTransfer(fromTokenId_, toTokenId_, value_);
    }
    
    // --- METADATA HELPERS ---

    function slotName(uint256 slotId_) external view returns (string memory) {
        return _registry.slot(slotId_).name;
    }
    
    function slotDescription (uint256 slotId_) external view returns (string memory) {
        return _registry.slot(slotId_).description;
    }
    
    function exists(uint256 slotId) public view returns (bool){
        return bytes(_registry.slot(slotId).name).length > 0;
    }
    
    function slotURI(uint256 slotId_) public view override returns (string memory) {
        return _registry.slot(slotId_).slotURI;
    }
    
    
}
