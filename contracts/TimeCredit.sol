//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//import "@openzeppelin/contracts/access/Ownable.sol";
import "./Service.sol";
import "./underlying/WUSDC.sol";
import "./SlotRegistry.sol";






contract TimeCredit is Service {
	
	struct ValidPeriod{
	    uint256 start;
	    uint256 expiration;
	}
	//uint256 private _defaultSlot;
	mapping(uint256 => ValidPeriod) internal token_period;
	mapping(uint256 => uint256) private _timeValueRate;
	mapping(uint256 => bool) private _transferAllowed;
	mapping(uint256 => uint256) private _minAllowedValueTransferSecs;
	
	
	
	address private _revenueAcct;
	IValue private _valueContract;
	
	// bool _transferAllowed;
	// uint256 _minAllowedValueTransferSecs;
	uint8 _decimals;
	string private _dispTimeUnit;
	
	
	event MintTimeToken(uint256 value_seconds, uint256 value_unit);
	
	
	
	constructor(address revenueAcct_,
        		address serviceAdmin_,
        		address slotRegistry_,
        		address underlyingContract_,
        		address mktAdmin_,
        		uint256 defaultSlot_,
        		string memory name_, 
        		string memory symbol_, 
        		string memory baseuri_,
        		string memory contractDescription_,
        		string memory contractImage_,
        		string memory dispTimeUnit_, 
        		string memory valueToken_, 
        		uint8 decimals_) 
        		Service(serviceAdmin_, mktAdmin_, slotRegistry_, defaultSlot_, name_, symbol_, baseuri_, string(abi.encodePacked(contractDescription_, "\n Time units: ", dispTimeUnit_)) , contractImage_, 'time',  decimals_) {

        		
        		_defaultSlot = defaultSlot_;
				if( keccak256(bytes(valueToken_)) == keccak256(bytes("USDC")) ){
		            _valueContract = WUSDC(underlyingContract_); 
		        }
			        
       _revenueAcct = revenueAcct_;
       _dispTimeUnit = dispTimeUnit_;
       _decimals = decimals_;
	}
	
	
	
	
	
	function mintTime(address owner_, 
        			uint256 slot_, 
        			uint256 time_value_,
        			uint256 paid_value,
        			uint256 valid_start,
        			uint256 valid_expiration,
        			string memory uuid_,
        			string memory token_description_,
        			string memory token_image_,
        			bool transfersAllowed_,
        			uint256 minAllowedValueTransfer_
    ) public virtual returns (uint256) {
        
        			
        uint256 time_value_seconds;
        
        
        /*if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('seconds'))){
            time_value_seconds = time_value_ / (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('minutes'))){
            time_value_seconds = time_value_ * 60 / (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('hours'))){
            time_value_seconds = time_value_ * 60 * 60 / (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('days'))){
            time_value_seconds = time_value_ * 24 * 60 * 60 / (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('weeks'))){
            time_value_seconds = time_value_ * 7 * 24 * 60 * 60 / (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('months'))){
            time_value_seconds = time_value_ * 60 * 60 * 24 * 304167 / (10 ** _decimals) / 10000;
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('years'))){
			time_value_seconds = time_value_ * (60 * 60 * 24 * 304167 * 12) / (10 ** _decimals) / 10000;
		}*/
		
		time_value_seconds = toSeconds(time_value_);
		
 		require(valid_start <= valid_expiration, "TimeCredit: valid start time must be less than expiration time");
 		require(block.timestamp <= valid_expiration, "TimeCredit: cannot mint an expired token");
 		require(
 		    (block.timestamp <= valid_start) && (time_value_seconds <= (valid_expiration - valid_start))
 		    		|| (block.timestamp > valid_start && block.timestamp < valid_expiration) && (time_value_seconds <= (valid_expiration - block.timestamp)), 
 		    			"TimeCredit: time value cannot exceed valid period"
 		);
 		
		_valueContract.mint(address(this), paid_value);
		
		uint256 tVRate = (paid_value * (10 ** _decimals) / time_value_seconds);
		uint256 tokenId;
		
		if(slot_ == _defaultSlot){
		    tokenId = super.mint(owner_, slot_, time_value_seconds, uuid_, token_description_, token_image_);
		}else{
		    uint256 regTokenId = Service.networkMintWithTVRate(owner_, slot_, time_value_seconds, tVRate, uuid_, token_description_, token_image_);
           	tokenId = ERC3525._createOriginalTokenId();
           	networkTokenId[tokenId] = regTokenId;
           
		}
	
        			
 		emit MintTimeToken(time_value_seconds, time_value_);
 		
        _transferAllowed[tokenId] = transfersAllowed_;
        _minAllowedValueTransferSecs[tokenId] = toSeconds(minAllowedValueTransfer_);
       
        _timeValueRate[tokenId] = tVRate;

        
        ValidPeriod memory period = ValidPeriod({
            start: valid_start,
			expiration: valid_expiration
        });
  
  		token_period[tokenId] = period;
 		
	    return tokenId;
  	}
  	
  	
  	
  	function toSeconds(uint256 time_value_) private view returns (uint256){
  	    uint256 time_value_seconds;
        
        
        if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('seconds'))){
            time_value_seconds = time_value_ / (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('minutes'))){
            time_value_seconds = time_value_ * 60 / (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('hours'))){
            time_value_seconds = time_value_ / (10 ** _decimals) * 60 * 60 ;
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('days'))){
            time_value_seconds = time_value_ * 24 * 60 * 60 / (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('weeks'))){
            time_value_seconds = time_value_ * 7 * 24 * 60 * 60 / (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('months'))){
            time_value_seconds = time_value_ * 60 * 60 * 24 * 30 / (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('years'))){
			time_value_seconds = time_value_ * (60 * 60 * 24 * 30 * 12) / (10 ** _decimals);
		}
		
		return time_value_seconds;
  	}
  	
  	
  	function isValid(uint256 tokenId_) public view virtual returns (bool) {
  	    
		return (block.timestamp >= token_period[tokenId_].start) && (block.timestamp < token_period[tokenId_].expiration);    
  	}
  	
  	
  	
  	
  	
  	function calcToTokenTimeValueRate(uint256 fromTokenId_, uint256 toTokenId_, uint256 amountTransferred_) private view returns (uint256){
  	    require(isInternalToken(fromTokenId_) && isInternalToken(toTokenId_), "TimeCredit: calc contract time-value rate requires contract tokens");
  	    uint256 toTokenValue = ERC3525.balanceOf(toTokenId_);
  	    
  	    return (_timeValueRate[fromTokenId_] * amountTransferred_ + _timeValueRate[toTokenId_] * toTokenValue) / (amountTransferred_ + toTokenValue);

  	}
  	
  	
  	
  	
  	
  	
  	function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override returns (uint256) {
        uint256 value = toSeconds(value_);
        require(_transferAllowed[fromTokenId_], "TimeCredit: transfers are not allowed");
        require(value >= _minAllowedValueTransferSecs[fromTokenId_], "TimeCredit: amount being transfered is less than minimum transferable value");
        require(block.timestamp < token_period[fromTokenId_].expiration, "TimeCredit: cannot transfer from an expired token");
        
        return super.transferFrom(fromTokenId_, to_, value);
    }
    
    
    
    
    
    
    
    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable virtual override {
		uint256 valueSeconds = toSeconds(value_);
		
		require(_transferAllowed[fromTokenId_], "TimeCredit: transfers are not allowed");
		require(valueSeconds >= _minAllowedValueTransferSecs[fromTokenId_], "TimeCredit: amount being transfered is less than minimum transferable value");

        require(block.timestamp < token_period[fromTokenId_].expiration, "TimeCredit: cannot transfer time from an expired token");
        require(block.timestamp <  token_period[toTokenId_].expiration, "TimeCredit: cannot transfer time into an expired token");
        require(block.timestamp + ERC3525.balanceOf(toTokenId_) <= token_period[toTokenId_].expiration, "TimeCredit: time value of token receiving transfer exceeds time till expiration");
		
		if(isContractToken(fromTokenId_) && isContractToken(toTokenId_)){
		    
	        if(_timeValueRate[fromTokenId_] != _timeValueRate[toTokenId_]){
	            _timeValueRate[toTokenId_] = calcToTokenTimeValueRate(fromTokenId_, toTokenId_, valueSeconds);
	        }
	        super.transferFrom(fromTokenId_, toTokenId_, valueSeconds);
		}else if(isContractToken(fromTokenId_) && !isContractToken(toTokenId_)){
		    /* canot transfer */
		    
		}else if(isInternalToken(fromTokenId_) && isInternalToken(toTokenId_)){
		    
		    super.transferFrom(fromTokenId_, toTokenId_, valueSeconds);
		    
		}else if(isInternalToken(fromTokenId_) && !isInternalToken(toTokenId_)){
		    address toContractAddress = slotRegistry.contractOf(toTokenId_);
		    uint256 networkTokenId = networkTokenId[fromTokenId_];
		    
		    uint256 tVRate = (networkTokenId != 0) ? slotRegistry.timeValueRate(networkTokenId) : slotRegistry.timeValueRate(fromTokenId_);
		    uint256 uValue =  tVRate * valueSeconds / (10 ** _decimals);
		    _valueContract.transfer(toContractAddress, uValue);
		}else{
		    /* no transfer */
		}
		
    }
    
    
    
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override {
        require(_transferAllowed[tokenId_], "TimeCredit: transfers are not allowed");
		require(balanceOf(tokenId_) >= _minAllowedValueTransferSecs[tokenId_], "TimeCredit: token value is less than minimum transferable value");
		
        super.transferFrom(from_, to_, tokenId_);
    }
    
    
    
  	
  	
  	function redeem(uint256 tokenId_, uint256 valueSeconds_) external {
	    
	   require(ERC3525.ownerOf(tokenId_) == msg.sender || hasRole(MKT_ARBITRATOR_ROLE, msg.sender), "Sender is not authorized to redeem.");
	   uint256 uValue;
	   
	   if(isContractToken(tokenId_)){
	       uValue =  _timeValueRate[tokenId_] * valueSeconds_ / (10 ** _decimals);
	   }else if(isInternalToken(tokenId_)){
	       uint256 netTokenId = networkTokenId[tokenId_];
	       if(netTokenId != 0){
	           uValue = slotRegistry.timeValueRate(netTokenId) * valueSeconds_ / (10 ** _decimals); 
	       }else{
	           uValue = slotRegistry.timeValueRate(tokenId_) * valueSeconds_ / (10 ** _decimals); 
	       }
	   }
	   
	   _valueContract.redeem(_revenueAcct, uValue);
	   super._burnValue(tokenId_, valueSeconds_);
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
		
		uint256 balance = super.balanceOf(tokenId_);
		
       if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('seconds'))){
            return balance * (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('minutes'))){
            return (balance * (10 ** _decimals)) / 60;
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('hours'))){
            return (balance  * (10 ** _decimals)) / (60 * 60);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('days'))){
            return (balance * (10 ** _decimals)) / (60 * 60 * 24);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('months'))){
            return (balance * (10 ** _decimals)) / (60 * 60 * 24 * 30);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('years'))){
			return (balance * (10 ** _decimals)) / (60 * 60 * 24 * 30 * 12);
		}else{
		    return balance * (10 ** _decimals);
		}
    }
    
    
    
    
    
    
}