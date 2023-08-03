
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;



import "./Service.sol";








contract SpendCredit is Service {
    

	IValue private _valueContract;
	uint256 _decimals;
	address _revenueAcct;
	uint256 _totalBalance;
	mapping(uint256 => uint256) private _tokenDiscount;
	
	event MintNetworkServiceToken(uint256  tokenId, uint256 slot, uint256 value);
	event MintSpendToken(uint256  tokenId, uint256 slot, uint256 value);
	
	
	
	
	

    constructor(address revenueAcct_,
        		address serviceAdmin_,
        		address slotRegistryContract_,
        		address underlyingContract_,
        		address mktAdmin_,
        		uint256 defaultSlot_,
        		string memory name_, 
        		string memory symbol_, 
        		string memory baseuri_,
        		string memory contractDescription_,
        		string memory contractImage_,
        		string memory valueToken_,
        		uint8 decimals_) Service(serviceAdmin_, mktAdmin_, slotRegistryContract_, defaultSlot_, name_, symbol_, baseuri_, contractDescription_, contractImage_, 'monetary', decimals_) {

        if( keccak256(bytes(valueToken_)) == keccak256(bytes("USDC")) ){
            _valueContract = WUSDC(underlyingContract_); 
        }
    
        _revenueAcct = revenueAcct_;
        _decimals = decimals_;
        
        
    }
    
    
    
    

 
 
 	
    function mintWithDiscount(address owner_, 
        			uint256 slot_, 
        			uint256 value_,
        			uint256 discountBasisPts_,
        			string memory uuid_,
        			string memory tokenDescription_,
        			string memory tokenImage_
    ) public virtual returns (uint256) {
 
       
       uint256 tokenId;
       if(slot_ == _defaultSlot){
           
           tokenId = Service.mint(owner_, slot_, value_, uuid_, tokenDescription_, tokenImage_);
           emit MintSpendToken(tokenId, slot_, value_);
       }else{
           //uint256 regTokenId = Service.mint(owner_, slot_, value_, uuid_, tokenDescription_, tokenImage_);
           uint256 regTokenId = Service.networkMintWithDiscount(owner_, slot_, value_, discountBasisPts_, uuid_, tokenDescription_, tokenImage_);
           tokenId = ERC3525._createOriginalTokenId();
           networkTokenId[tokenId] = regTokenId;
           emit MintNetworkServiceToken(regTokenId, slot_, value_);
          
       }
       
       _totalBalance += value_;
       _tokenDiscount[tokenId] = discountBasisPts_ / (10 ** _decimals);
       
       uint256 tenKBasisPts = 10000;
       uint256 uValue = (tenKBasisPts - _tokenDiscount[tokenId]) * value_ / tenKBasisPts;
       _valueContract.mint(address(this), uValue);
       
       
	   return tokenId;
  	}
  
  	
  	
  	
  	function mint(address owner_, 
        			uint256 slot_, 
        			uint256 value_,
        			string memory uuid_,
        			string memory tokenDescription_,
        			string memory tokenImage_
    ) public virtual override returns (uint256) {
        uint256 discountBasisPts_ = 0;

        uint256 tokenId = mintWithDiscount(owner_, slot_, value_, discountBasisPts_, uuid_, tokenDescription_, tokenImage_);
        emit MintSpendToken(tokenId, slot_, value_);
        return tokenId;
       
  	}
  	
  	
  	
  	
	function redeem(uint256 tokenId_, uint256 value_) external {
	    
	   require(ERC3525.ownerOf(tokenId_) == msg.sender || hasRole(MKT_ARBITRATOR_ROLE, msg.sender), "Sender is not authorized to redeem.");
	   uint256 uValue =  (10000 - _tokenDiscount[tokenId_]) * value_ / 10000;
	   _valueContract.redeem(_revenueAcct, uValue);
	   _totalBalance -= value_;
	   super._burnValue(tokenId_, value_);
	}
    
    
    
    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override returns (uint256) {
        return super.transferFrom(fromTokenId_, to_, value_);
        //address fromOwnerAddress = _allTokens[_allTokensIndex[fromTokenId_]].owner;
    }


	function totalBalance() public view returns (uint256){
	    return _totalBalance;
	}

	
	
	function networkId(uint256 tokenId_) public view returns (uint256){
	    _requireMinted(tokenId_);
	    return networkTokenId[tokenId_];
	}
	
	
	


    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable virtual override {
        /* check both tokens are SpendCredit token */
        
        
        if(isContractToken(fromTokenId_) && isContractToken(toTokenId_)){
            uint256 tenKBasisPts = 10000;
	        uint256 toTokenValue = super.balanceOf(toTokenId_);
	        
	        if(_tokenDiscount[fromTokenId_] != _tokenDiscount[toTokenId_]){
	            _tokenDiscount[toTokenId_]  = tenKBasisPts - ((tenKBasisPts - _tokenDiscount[fromTokenId_]) * value_ + (tenKBasisPts - _tokenDiscount[toTokenId_]) * toTokenValue) / (value_ + toTokenValue);
	        }else{
	            _tokenDiscount[toTokenId_]  = _tokenDiscount[toTokenId_];
	        }
        
        
        
            //_tokenDiscount[toTokenId] = calcContractTokenDiscount(fromTokenId_, toTokenId_, value_);
            super.transferFrom(fromTokenId_, toTokenId_, value_);
        }else if(isContractToken(fromTokenId_) && !isContractToken(toTokenId_)){
        	/* transfer not allowed :different slots */
        }else if(isInternalToken(fromTokenId_) && isInternalToken(toTokenId_)){
            
            super.transferFrom(fromTokenId_, toTokenId_, value_);
            /* no change to underlying pool since 
             * address(this) is contract for fromToken and toToken
             */
             
        }else if(isInternalToken(fromTokenId_) && isExternalToken(toTokenId_)){
            //address fromContractAddress = slotRegistry.contractOf(fromTokenId_);
            //require(fromContractAddress == address(this), "SpendCredit: cannot transfer another contract's underlying value");
            super.transferFrom(fromTokenId_, toTokenId_, value_);
            _totalBalance -= value_;
            
            address toContractAddress = slotRegistry.contractOf(toTokenId_);
            uint256 netTokenId = networkTokenId[fromTokenId_];
            
            uint256 discountBasisPts = (netTokenId != 0) ? slotRegistry.tokenDiscount(netTokenId): slotRegistry.tokenDiscount(fromTokenId_);
			uint256 uValue =  (10000 - discountBasisPts) * value_ / 10000;
            _valueContract.transfer(toContractAddress, uValue);
 
            emit ValueTransfer(fromTokenId_,  toTokenId_, value_);	
        }else if(!isInternalToken(fromTokenId_)){
            /* transfer not allowed since fromToken not belong to this contract */
        }
    }
    
    






    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override {
        super.transferFrom( from_, to_, tokenId_);
    }
    
}