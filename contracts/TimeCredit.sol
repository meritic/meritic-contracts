//SPDX-License-Identifier: 	BUSL-1.1

pragma solidity ^0.8.9;

import "./Service.sol";
import "./interfaces/ILedgerUpdate.sol";
import "./RoyaltyDistributor.sol";






interface IPool {
    function poolToken(uint256 slotId_, uint256 tokenId_) external;
    function tokenValueRate(uint256 tokenId_) external view returns (uint256);
    function contractOf(uint256 tokenId_) external view returns (address);
}


contract TimeCredit is Service, ILedgerUpdate {
	
	struct ValidPeriod {
	    uint256 start;
	    uint256 expiration;
	}

	mapping(uint256 => ValidPeriod) internal tokenPeriod;
	mapping(uint256 => uint256) private _timeValueRate;
	mapping(uint256 => bool) private _transferAllowed;
	mapping(uint256 => uint256) private _minAllowedValueTransferSecs;
	
	
	
	// Solvency Ledger: Tracks total Underlying (Underlying) per slot
    mapping(uint256 => uint256) internal _slotUnderlyingBalance;

	
	string private _dispTimeUnit;
	
	event MintTimeToken(uint256 tokenId, uint256 valueSeconds, uint256 valueUnit);
	/*
    event CreditsConsumed(uint256 tokenId, uint256 timeUnitValue, uint256 underlyingValue, uint256 royaltyValue);
	*/

	constructor(
        address revenueAcct_,
        address slotRegistryContract_,
        address poolContract_,
        address underlyingContract_,
        address mktAdmin_,
        uint256 defaultSlot_,
        string memory name_, 
        string memory symbol_, 
        string memory baseUri_,
        string memory contractDescription_,
        string memory contractImage_,
        string memory dispTimeUnit_, 
        uint8 decimals_
    ) Service(revenueAcct_, mktAdmin_, slotRegistryContract_, poolContract_, underlyingContract_, defaultSlot_, name_, symbol_, baseUri_, string(abi.encodePacked(contractDescription_, "\n Time units: " , dispTimeUnit_)), contractImage_, 'time',  decimals_) {
    	
    	_dispTimeUnit = dispTimeUnit_;

	}
	
	
	
	/**
     * @notice Consumes time credits (Units).
     * @param tokenId_ Token ID.
     * @param unitValue_ Amount of TIME UNITS (e.g., Hours) to consume.
     */
    function consumeCredits(uint256 tokenId_, uint256 unitValue_) external {
        _consumeLogic(tokenId_, unitValue_, new address[](0), new uint256[](0));
    }

    function consumeWithRoyalties(
        uint256 tokenId_, 
        uint256 unitValue_, 
        address[] calldata royaltyRecipients, 
        uint256[] calldata royaltyAmounts
    ) external {
        _consumeLogic(tokenId_, unitValue_, royaltyRecipients, royaltyAmounts);
    }

    function _consumeLogic(
        uint256 tokenId_, 
        uint256 unitValue_, 
        address[] memory royaltyRecipients, 
        uint256[] memory royaltyAmounts
    ) internal {
        require(hasRole(SERVICE_ADMIN_ROLE, msg.sender), "Caller is not a service admin");
        
        // _consumeCore handles the burn and returns the total Underlying value of that time
        uint256 totalUnderlyingValue = _consumeCore(tokenId_, unitValue_);
        uint256 totalRoyalty = 0;
        
        if (royaltyRecipients.length > 0) {
            require(address(royaltyDistributor) != address(0), "Distributor not set");
            require(royaltyRecipients.length == royaltyAmounts.length, "Array mismatch");

            for(uint i = 0; i < royaltyAmounts.length; i++) {
                totalRoyalty += royaltyAmounts[i];
            }
            // Cap check: Royalties cannot exceed 10% of the total underlying value consumed
            require(totalRoyalty <= (totalUnderlyingValue * 1000) / 10000, "Royalties exceed 10%");

            if (totalRoyalty > 0) {
                royaltyDistributor.depositRoyalties(royaltyRecipients, royaltyAmounts);
            }
        }

        uint256 platformRevenue = totalUnderlyingValue - totalRoyalty;
        if (platformRevenue > 0) {
            require(_underlying.transfer(_revenueAddress, platformRevenue), "Revenue transfer failed");
        }

        emit CreditsConsumed(tokenId_, unitValue_, totalUnderlyingValue, totalRoyalty);
    }
    
    

    function _consumeCore(uint256 tokenId_, uint256 unitValue_) internal returns (uint256 totalUnderlyingValue) {
        // Convert Units (e.g. Hours) to Seconds for internal storage/burn
        uint256 secondsToBurn = toSeconds(unitValue_);
        
        // Standard check: balanceOf returns Units, but underlying storage is Seconds.
        // Since we are overriding balanceOf to return units, this check is correct for unit comparison.
        require(balanceOf(tokenId_) >= unitValue_, "Insufficient time balance");

        // 1. Get Rate (Underlying per Second)
        uint256 rate;
        if (isContractToken(tokenId_)) {
            rate = _timeValueRate[tokenId_];
        } else {
            uint256 netTokenId = networkTokenId[tokenId_];
            rate = (netTokenId != 0) ? _slotPool.tokenValueRate(netTokenId) : _slotPool.tokenValueRate(tokenId_);
        }
        
        // 2. Calculate Underlying Value
        // Value = (Seconds * Rate) / Precision
        totalUnderlyingValue = (rate * secondsToBurn) / (10 ** _decimals);

        // 3. Burn Seconds from the token
        super._burnValue(tokenId_, secondsToBurn);
        
        // 4. Update Ledger
        uint256 slot = ERC3525.slotOf(tokenId_);
        require(_slotUnderlyingBalance[slot] >= totalUnderlyingValue, "Insufficient slot liquidity");
        _slotUnderlyingBalance[slot] -= totalUnderlyingValue;

        return totalUnderlyingValue;
    }
	
	
	
	
	function mintTime(
        address owner_, 
        uint256 slotId_, 
        uint256 timeValue_, // In Units (e.g., Hours)
        uint256 paidValue_, // In Underlying
        uint256 validStart_,
        uint256 validExpiration_,
        string memory uuid_,
        string memory tokenDescription_,
        string memory tokenImage_,
        string memory property_,
        bool transfersAllowed_,
        uint256 minAllowedValueTransfer_
    ) public virtual returns (uint256) {
        
        require(hasRole(SERVICE_ADMIN_ROLE, msg.sender), "Caller is not a minter");
        
        uint256 timeValueSeconds = toSeconds(timeValue_);
        
 		require(validStart_ <= validExpiration_, "TimeCredit: valid start time must be less than expiration");
 		require(block.timestamp <= validExpiration_, "TimeCredit: cannot mint expired token");
 		
        // Valid period check logic (unchanged from original)
 		require(
 		    (block.timestamp <= validStart_) && (timeValueSeconds <= (validExpiration_ - validStart_))
 		    		|| (block.timestamp > validStart_ && block.timestamp < validExpiration_) && (timeValueSeconds <= (validExpiration_ - block.timestamp)), 
 		    			"TimeCredit: time value cannot exceed valid period"
 		);
 		
 		// 1. Pull Funds
		_underlying.transferFrom(msg.sender, address(this), paidValue_);
		
        // 2. Calculate Rate (Underlying per Second)
		uint256 newRate = (paidValue_ * (10 ** _decimals) / timeValueSeconds);
		uint256 tokenId;

		if(slotId_ == _defaultSlot){
            // Smart Minting: Checks cache, adds to existing if found
		    tokenId = Service.mint(owner_, slotId_, timeValueSeconds, uuid_, tokenDescription_, tokenImage_, property_);
            
            // Check if we added to an existing token (Smart Mint)
            // Note: We use super.balanceOf (internal storage) to get raw seconds
            uint256 currentSeconds = super.balanceOf(tokenId);
            uint256 prevSeconds = currentSeconds - timeValueSeconds;

            if (prevSeconds > 0 && _timeValueRate[tokenId] > 0) {
                // Weighted Average Rate
                uint256 oldVal = prevSeconds * _timeValueRate[tokenId];
                uint256 newVal = timeValueSeconds * newRate;
                _timeValueRate[tokenId] = (oldVal + newVal) / currentSeconds;
                
                // Extend Expiration: If new expiration is later, update it
                if (validExpiration_ > tokenPeriod[tokenId].expiration) {
                    tokenPeriod[tokenId].expiration = validExpiration_;
                }
            } else {
                // New Token
                _timeValueRate[tokenId] = newRate;
                tokenPeriod[tokenId] = ValidPeriod({ start: validStart_, expiration: validExpiration_ });
            }

		} else {
            // Network Mint (New ID)
		    tokenId = Service.networkMintWithValueRate(owner_, slotId_, timeValueSeconds, newRate, uuid_, tokenDescription_, tokenImage_, property_);
            tokenPeriod[tokenId] = ValidPeriod({ start: validStart_, expiration: validExpiration_ });
            _timeValueRate[tokenId] = newRate;
		}
		
        // 3. Set properties
        _transferAllowed[tokenId] = transfersAllowed_;
        _minAllowedValueTransferSecs[tokenId] = toSeconds(minAllowedValueTransfer_);
        
        // 4. Update Ledger
        _slotUnderlyingBalance[slotId_] += paidValue_;

 		emit MintTimeToken(tokenId, timeValueSeconds, timeValue_);
	    return tokenId;
  	}
  	
    // --- REDEMPTION ---

  	function redeem(uint256 tokenId_, uint256 valueUnit_) external {
	   require(ERC3525.ownerOf(tokenId_) == msg.sender, "Sender not authorized.");
       
       // Use core logic to calculate value and burn
       uint256 totalUnderlyingValue = _consumeCore(tokenId_, valueUnit_);
       
       // Refund user
       require(_underlying.transfer(msg.sender, totalUnderlyingValue), "Transfer failed");
	}
	
    // --- UTILS ---

  	function toSeconds(uint256 timeValue_) private view returns (uint256){
  	    uint256 timeValueSeconds;
        
        if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('seconds'))){
            timeValueSeconds = timeValue_ / (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('minutes'))){
            timeValueSeconds = timeValue_ * 60 / (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('hours'))){
            timeValueSeconds = timeValue_ / (10 ** _decimals) * 60 * 60 ;
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('days'))){
            timeValueSeconds = timeValue_ * 24 * 60 * 60 / (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('weeks'))){
            timeValueSeconds = timeValue_ * 7 * 24 * 60 * 60 / (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('months'))){
            timeValueSeconds = timeValue_ * 60 * 60 * 24 * 30 / (10 ** _decimals);
        }else if(keccak256(bytes(_dispTimeUnit)) == keccak256(bytes('years'))){
			timeValueSeconds = timeValue_ * (60 * 60 * 24 * 30 * 12) / (10 ** _decimals);
		}
		return timeValueSeconds;
  	}
  	
  	function isValid(uint256 tokenId_) public view virtual returns (bool) {
		return (block.timestamp >= tokenPeriod[tokenId_].start) && (block.timestamp < tokenPeriod[tokenId_].expiration);    
  	}
  	
  	
  	
  	
  	
  	
  	
  	function addSlotLiquidity(uint256 slotId, uint256 amount) external override {
        _slotUnderlyingBalance[slotId] += amount;
    }

  	function calcToTokenTimeValueRate(uint256 fromTokenId_, uint256 toTokenId_, uint256 amountTransferred_) private view returns (uint256){
        // Note: balanceOf here uses the override, so it returns Units.
        // But amountTransferred_ passed from transferFrom is Seconds.
        // We need to be careful with units here. 
        // Ideally we use internal balance (seconds) for rate calc to be precise.
  	    uint256 toTokenSeconds = super.balanceOf(toTokenId_); 
  	    return (_timeValueRate[fromTokenId_] * amountTransferred_ + _timeValueRate[toTokenId_] * toTokenSeconds) / (amountTransferred_ + toTokenSeconds);
  	}
  	
    // Override transferFrom (Standard ERC3525 value transfer)
    function transferFrom(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_) public payable virtual override {
        // The 'value_' coming into ERC3525 transferFrom is typically raw amount (Seconds in our storage)
        // However, in our system, users might expect to pass Units.
        // STANDARD: ERC3525 transfers usually deal with raw stored values.
        // NOTE: The previous implementation converted input to Seconds. We will maintain that.
		uint256 valueSeconds = toSeconds(value_);
		
		require(_transferAllowed[fromTokenId_], "TimeCredit: transfers not allowed");
		require(valueSeconds >= _minAllowedValueTransferSecs[fromTokenId_], "TimeCredit: below min transfer");

        require(block.timestamp < tokenPeriod[fromTokenId_].expiration, "TimeCredit: source expired");
        require(block.timestamp < tokenPeriod[toTokenId_].expiration, "TimeCredit: target expired");
        // Ensure adding time doesn't push it past expiration (logic from old contract)
        require(block.timestamp + super.balanceOf(toTokenId_) <= tokenPeriod[toTokenId_].expiration, "TimeCredit: exceeds expiration");
		
		if(isContractToken(fromTokenId_) && isContractToken(toTokenId_)){
            // Internal Transfer
	        if(_timeValueRate[fromTokenId_] != _timeValueRate[toTokenId_]){
	            _timeValueRate[toTokenId_] = calcToTokenTimeValueRate(fromTokenId_, toTokenId_, valueSeconds);
	        }
	        super.transferFrom(fromTokenId_, toTokenId_, valueSeconds);

		} else if(!isContractToken(fromTokenId_) && !isContractToken(toTokenId_)){
            // Network Transfer
            uint256 netTokenId = networkTokenId[fromTokenId_];
            address toContractAddress = _slotPool.contractOf(toTokenId_);
		    
		    super.transferFrom(fromTokenId_, toTokenId_, valueSeconds);
		    
		    if (toContractAddress != address(this)) {
                uint256 tVRate = (netTokenId != 0) ? _slotPool.tokenValueRate(netTokenId) : _slotPool.tokenValueRate(fromTokenId_);
                
                uint256 uValue = tVRate * valueSeconds / (10 ** _decimals);
                uint256 slot = ERC3525.slotOf(fromTokenId_);

                require(_slotUnderlyingBalance[slot] >= uValue, "Insufficient liquidity");
                _slotUnderlyingBalance[slot] -= uValue;

                require(_underlying.transfer(toContractAddress, uValue), "Transfer failed");
                ILedgerUpdate(toContractAddress).addSlotLiquidity(slot, uValue);
            }
		} else {
		    revert("TimeCredit: transfer type mismatch");
		}
    }
    
    // Override: Transfer entire token (ownership)
    function transferFrom(address from_, address to_, uint256 tokenId_) public payable virtual override {
        require(_transferAllowed[tokenId_], "TimeCredit: transfers not allowed");
        // Check using raw seconds balance
		require(super.balanceOf(tokenId_) >= _minAllowedValueTransferSecs[tokenId_], "TimeCredit: below min transfer value");
		
        super.transferFrom(from_, to_, tokenId_);
    }
    
    // Override: Compatibility wrapper
    function transferFrom(uint256 fromTokenId_, address to_, uint256 value_) public payable virtual override returns (uint256) {
        uint256 valueSeconds = toSeconds(value_);
        // Basic checks before calling super
        require(_transferAllowed[fromTokenId_], "TimeCredit: transfers not allowed");
        require(valueSeconds >= _minAllowedValueTransferSecs[fromTokenId_], "TimeCredit: below min transfer");
        require(block.timestamp < tokenPeriod[fromTokenId_].expiration, "TimeCredit: expired");
        
        return super.transferFrom(fromTokenId_, to_, valueSeconds);
    }
    
    
    
    

    // Assuming ADMIN ONLY or INTERNAL use.
	function addTime(uint256 tokenId_, uint256 valueSeconds_) external {
        require(hasRole(SERVICE_ADMIN_ROLE, msg.sender), "Not admin");

	    require(block.timestamp < tokenPeriod[tokenId_].expiration, "TimeCredit: expired");
	    
        // Update expiration if the new time pushes balance beyond current expiration
        uint256 currentBal = super.balanceOf(tokenId_);
        if(block.timestamp + currentBal + valueSeconds_ > tokenPeriod[tokenId_].expiration){
	        tokenPeriod[tokenId_].expiration = block.timestamp + currentBal + valueSeconds_;
	    }
	    super._mintValue(tokenId_, valueSeconds_);
	}
	
	
	
	
	
	
	
	
	// Override balanceOf to return UNITS (e.g. Hours) instead of Seconds
	function balanceOf(uint256 tokenId_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
		
        // Get raw seconds
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