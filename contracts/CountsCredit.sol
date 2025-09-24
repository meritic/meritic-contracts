
//SPDX-License-Identifier: 	BUSL-1.1
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "./Service.sol";
import "./Pool.sol";







contract CountsCredit is Service {
    
	uint256 _decimals;
	Underlying private _valueContract;
	IERC20 private _underlyingUSDC;
	address _revenueAcct;
	uint256 _totalBalance;
	mapping(uint256 => uint256) private _countValueRate;
	
	event MintNetworkServiceToken(uint256  tokenId, uint256 slot, uint256 value);
	event MintCountsToken(uint256  tokenId, uint256 slot, uint256 value);
	event CreditsConsumed(uint256 indexed tokenId, uint256 consumedValue, uint256 underlyingBurntValue);
	
	
	Pool internal _poolContract;
	
	

    constructor(address revenueAcct_,
        		address slotRegistryContract_,
        		address poolContract_,
        		address valueContract_,
        		address USDContract_,
        		address mktAdmin_,
        		uint256 defaultSlot_,
        		string memory name_, 
        		string memory symbol_, 
        		string memory baseuri_,
        		string memory contractDescription_,
        		string memory contractImage_,
        		string memory valueToken_, 
        		uint8 decimals_) Service(revenueAcct_, mktAdmin_, slotRegistryContract_, poolContract_, valueContract_, defaultSlot_, name_, symbol_ , baseuri_, contractDescription_, contractImage_, 'counts', decimals_) {

		_underlyingUSDC = IERC20(USDContract_); 
        _valueContract = WUSDC(valueContract_);
        

        _revenueAcct = revenueAcct_;
        _decimals = decimals_;
        _poolContract = Pool(poolContract_);
    }
    
    
    /**
	 * @notice Allows a service admin to consume a specified value of credits from a token.
	 * @dev This should be called by the trusted backend service wallet.
	 * @param tokenId_ The ID of the token from which to consume credits.
	 * @param value_ The amount of credits to consume (in the token's native decimals).
	 */
	function consumeCredits(uint256 tokenId_, uint256 value_) external {
	    require(hasRole(SERVICE_ADMIN_ROLE, msg.sender), "Caller is not a service admin");
	    require(balanceOf(tokenId_) >= value_, "Insufficient credit balance");
	
	    uint256 uValue; 
	    if (isContractToken(tokenId_)) {
	        uValue = _countValueRate[tokenId_] * value_ / (10**_decimals);
	    } else if (isInternalToken(tokenId_)) {
	        uint256 netTokenId = networkTokenId[tokenId_];
	        uint256 rate = (netTokenId != 0) ? _poolContract.tokenValueRate(netTokenId) : _poolContract.tokenValueRate(tokenId_);
	        uValue = rate * value_ / (10**_decimals);
	    } else {
	        revert("Token is not recognized");
	    }
	
	    super._burnValue(tokenId_, value_);
	    _valueContract.burn(address(this), slotOf(tokenId_), uValue);

	    _totalBalance -= value_;
	
	    emit CreditsConsumed(tokenId_, value_, uValue);
	}
    
    
    
    

 
 
 	
    function mintCounts(address owner_, 
        			uint256 slot_, 
        			uint256 countValue_,
        			uint256 paidValue_,
        			string memory uuid_,
        			string memory tokenDescription_,
        			string memory tokenImage_,
        			string memory property_
    ) public virtual returns (uint256) {
 
       _underlyingUSDC.transferFrom(msg.sender, address(this), paidValue_);
       
       uint256 tokenId;
       uint256 countRate = paidValue_ * (10 ** _decimals) / countValue_;
       
       if(slot_ == _defaultSlot){
           tokenId = Service.mint(owner_, slot_, countValue_, uuid_, tokenDescription_, tokenImage_, property_);
       }else{
           tokenId = Service.networkMintWithValueRate(owner_, slot_, countValue_, countRate, uuid_, tokenDescription_, tokenImage_, property_);
           emit MintNetworkServiceToken(networkTokenId[tokenId], slot_, countValue_);
       }
       
       emit MintCountsToken(tokenId, slot_, countValue_);
       
       _totalBalance += countValue_;
       
       _countValueRate[tokenId] = countRate;
       _valueContract.mint(address(this), slot_, paidValue_);
  

	   return tokenId;
  	}
  
  	
  	
  	

 
  	
	function redeem(uint256 tokenId_, uint256 slotId_, uint256 value_) external {
	    
	   require(ERC3525.ownerOf(tokenId_) == msg.sender || hasRole(MKT_ARBITRATOR_ROLE, msg.sender), "Sender is not authorized to redeem.");
	
	   uint256 uValue;
	   if(isContractToken(tokenId_)){
	       uValue =  _countValueRate[tokenId_] * value_ / (10 ** _decimals);
	   }else if(isInternalToken(tokenId_)){
	       uint256 netTokenId = networkTokenId[tokenId_];
	       if(netTokenId != 0){
	           uValue = _poolContract.tokenValueRate(netTokenId) * value_ / (10 ** _decimals); 
	       }else{
	           uValue = _poolContract.tokenValueRate(tokenId_) * value_ / (10 ** _decimals); 
	       }
	   }
	   super._burnValue(tokenId_, value_);
	   _valueContract.burn(address(this), slotId_, uValue);
	   
	   _underlyingUSDC.transfer(msg.sender, uValue);
	   
	   _totalBalance -= value_;
	   
	}
    
    
    
    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override returns (uint256) {
        return super.transferFrom(fromTokenId_, to_, value_);
    }


	function totalBalance() public view returns (uint256){
	    return _totalBalance;
	}

	
	
	function networkId(uint256 tokenId_) public view returns (uint256){
	    _requireMinted(tokenId_);
	    return networkTokenId[tokenId_];
	}
	
	
	function calcToTokenCountValueRate(uint256 fromTokenId_, uint256 toTokenId_, uint256 amountTransferred_) private view returns (uint256){
  	    require(isInternalToken(fromTokenId_) && isInternalToken(toTokenId_), "CountsCredit: calc contract count-value rate requires contract tokens");
  	    uint256 toTokenValue = ERC3525.balanceOf(toTokenId_);
  	    
  	    return (_countValueRate[fromTokenId_] * amountTransferred_ + _countValueRate[toTokenId_] * toTokenValue) / (amountTransferred_ + toTokenValue);

  	}


    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable virtual override {
        /* check both tokens are CashCredit token */
        
        if(isContractToken(fromTokenId_) && isContractToken(toTokenId_)){
         
	        //uint256 toTokenValue = super.balanceOf(toTokenId_);
	        
            if(_countValueRate[fromTokenId_] != _countValueRate[toTokenId_]){
	            _countValueRate[toTokenId_] = calcToTokenCountValueRate(fromTokenId_, toTokenId_, value_);
	        }
	        super.transferFrom(fromTokenId_, toTokenId_, value_);
	        
        }else if(!isContractToken(fromTokenId_) && !isContractToken(toTokenId_)){
     		
            uint256 netFromTokenId = networkTokenId[fromTokenId_];
            
            require(netFromTokenId != 0, "CountsToken: invalid sender token ID");
            
            _totalBalance -= value_;
            
            address toContractAddress = _poolContract.contractOf(toTokenId_);
            uint256 netTokenId = networkTokenId[fromTokenId_];
            
            
            super.transferFrom(fromTokenId_, toTokenId_, value_);
		    
		    
		    uint256 countValueRate = (netTokenId != 0) ? _poolContract.tokenValueRate(netTokenId) : _poolContract.tokenValueRate(fromTokenId_);
		    
		    uint256 uValue =  countValueRate * value_ / (10 ** _decimals);
		    _valueContract.transfer(toContractAddress, uValue);
		    
		    
            emit ValueTransfer(fromTokenId_,  toTokenId_, value_);	
           
        }else{
            revert("CountsCredit: transfer to token with different slot");
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