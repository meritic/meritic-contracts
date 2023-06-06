//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Service.sol";








contract TimeCredit is Service {
	
	struct ValidPeriod{
	    uint256 start;
	    uint256 expiration;
	}
	
	mapping(uint256 => ValidPeriod) token_period;
	
	bool _transferAllowed;
	uint256 _minAllowedValueTransfer;
	uint8 _decimals;
	string private _dispTimeUnit;
	
	
	constructor(address serviceAddress_,
        		address slotRegistry_,
        		string memory name_, 
        		string memory symbol_, 
        		string memory baseuri_,
        		string memory contractDescription_,
        		string memory contractImage_,
        		bool transfersAllowed_,
        		uint256 minAllowedValueTransfer_,
        		string memory dispTimeUnit_) 
        		Service(serviceAddress_, slotRegistry_, name_, symbol_, baseuri_, contractDescription_, contractImage_,  18) {
        		    
       _transferAllowed = transfersAllowed_;
       _minAllowedValueTransfer = minAllowedValueTransfer_;
       _decimals = 18;
       _dispTimeUnit = dispTimeUnit_;
	}
	
	
	function mint(address owner_, 
        			uint256 slot_, 
        			uint256 value_seconds_,
        			uint256 valid_start,
        			uint256 valid_expiration,
        			string memory uuid_,
        			string memory token_description_,
        			string memory token_image_
    ) public virtual returns (uint256) {
 
        uint256 tokenId = super.mint(owner_, slot_, value_seconds_, uuid_, token_description_, token_image_);
        
        ValidPeriod memory period = ValidPeriod({
            start: valid_start,
			expiration: valid_expiration
        });
  
  		token_period[tokenId] = period;
 
	    return tokenId;
  	}
  	
  	
  	function isValid(uint256 tokenId_) public view virtual returns (bool) {
  	    
		return (block.timestamp >= token_period[tokenId_].start) && (block.timestamp < token_period[tokenId_].expiration);    
  	}
  	
  	
  	function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override returns (uint256) {
        require(_transferAllowed && (value_ >= _minAllowedValueTransfer), "TimeCredit: this transfer is not allowed");
        require(block.timestamp < token_period[fromTokenId_].expiration, "TimeCredit: cannot transfer from an expired token");
        
        return super.transferFrom( fromTokenId_, to_, value_);
    }
    
    
    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable virtual override {

		require(_transferAllowed, "TimeCredit: transfers are not allowed");
		require(value_ >= _minAllowedValueTransfer, "TimeCredit: amount being transfered is less than minimum transferable value");

        require(block.timestamp < token_period[fromTokenId_].expiration, "TimeCredit: cannot transfer time from an expired token");
        require(block.timestamp <  token_period[toTokenId_].expiration, "TimeCredit: cannot transfer time into an expired token");
        require(block.timestamp + balanceOf(toTokenId_) <= token_period[toTokenId_].expiration, "TimeCredit: time value of token receiving transfer already exceeds time till expiration");
		
		super.transferFrom(fromTokenId_, toTokenId_, value_);
    }
    
    
    
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override {
        require(_transferAllowed, "TimeCredit: transfers are not allowed");
		require(balanceOf(tokenId_) >= _minAllowedValueTransfer, "TimeCredit: token value is less than minimum transferable value");
		
        super.transferFrom(from_, to_, tokenId_);
    }
    
    
    
  	function deductTime(uint256 tokenId_, uint256 value_seconds_) external {
  	    super._burnValue(tokenId_, value_seconds_);
  	}
	
	
	function addTime(uint256 tokenId_, uint256 valueSeconds_) external {

	    require(block.timestamp < token_period[tokenId_].expiration, "TimeCredit: cannot add time to an expired token");
	    if(block.timestamp + balanceOf(tokenId_) + valueSeconds_ > token_period[tokenId_].expiration){
	        token_period[tokenId_].expiration = block.timestamp + balanceOf(tokenId_) + valueSeconds_;
	    }
	    super._mintValue(tokenId_, valueSeconds_);
	}
	
	
	function balanceOf(uint256 tokenId_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);

        if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('seconds'))){
            return _allTokens[_allTokensIndex[tokenId_]].balance;
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('minutes'))){
            return (_allTokens[_allTokensIndex[tokenId_]].balance / (10 ** _decimals)) / 60 * (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('hours'))){
            return (_allTokens[_allTokensIndex[tokenId_]].balance / (10 ** _decimals)) / (60 * 60) * (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('days'))){
            return (_allTokens[_allTokensIndex[tokenId_]].balance / (10 ** _decimals)) / (60 * 60 * 24) * (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('months'))){
            return (_allTokens[_allTokensIndex[tokenId_]].balance / (10 ** _decimals)) / (60 * 60 * 24 * 304167) * (10 ** _decimals) / 10000;
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('years'))){
			return (_allTokens[_allTokensIndex[tokenId_]].balance / (10 ** _decimals)) / (60 * 60 * 24 * 304167 * 12) * (10 ** _decimals) / 10000;
		}else{
		    return 0;
		}
		
    }
}