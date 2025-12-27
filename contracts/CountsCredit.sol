
//SPDX-License-Identifier: 	BUSL-1.1
pragma solidity ^0.8.9;

import "./interfaces/ILedgerUpdate.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "./Service.sol";
import "./Pool.sol";







contract CountsCredit is Service {
    

	uint256 _totalBalance;
	mapping(uint256 => uint256) private _countValueRate;
	
	event MintCountsToken(uint256  tokenId, uint256 slot, uint256 value);
	/*event MintNetworkServiceToken(uint256  tokenId, uint256 slot, uint256 value);
	
	event CreditsConsumed(uint256 indexed tokenId, uint256 consumedValue, uint256 underlyingBurntValue);
	*/

	

	// Tracks the total backing underlying held by this contract for specific slots
	mapping(uint256 => uint256) internal _slotUnderlyingBalance;

	
	
	
    constructor(address revenueAcct_,
        		address slotRegistryContract_,
        		address poolContract_,
        		address underlyingContract_, 
        		address mktAdmin_,
        		uint256 defaultSlot_,
        		string memory name_, 
        		string memory symbol_, 
        		string memory baseuri_,
        		string memory contractDescription_,
        		string memory contractImage_, 
        		uint8 decimals_) Service(revenueAcct_, mktAdmin_, slotRegistryContract_, poolContract_, underlyingContract_, defaultSlot_, name_, symbol_ , baseuri_, contractDescription_, contractImage_, 'counts', decimals_) 
    { }
    
    

    
    
    function consumeCredits(uint256 tokenId_, uint256 value_) external {
        _consumeLogic(tokenId_, value_, new address[](0), new uint256[](0));
    }


    
    
    function consumeCredits(
    	uint256 tokenId_, 
    	uint256 value_,
    	uint256 nonce_, 
    	uint256 deadline_, 
        bytes calldata signature_
    ) external {
    	_verifySignature(tokenId_, value_, nonce_, deadline_, signature_);
        _consumeLogic(tokenId_, value_, new address[](0), new uint256[](0));
    }


	function consumeWithRoyalties(
        uint256 tokenId_, 
        uint256 consumeValue_, 
        address[] calldata royaltyRecipients, 
        uint256[] calldata royaltyAmounts
    ) external {
        _consumeLogic(tokenId_, consumeValue_, royaltyRecipients, royaltyAmounts);
    }

    function consumeWithRoyalties(
        uint256 tokenId_, 
        uint256 consumeValue_,
        address[] calldata royaltyRecipients, 
        uint256[] calldata royaltyAmounts,
        uint256 nonce_, 
    	uint256 deadline_, 
        bytes calldata signature_
    ) external {
    	_verifySignature(tokenId_, consumeValue_, nonce_, deadline_, signature_);
        _consumeLogic(tokenId_, consumeValue_, royaltyRecipients, royaltyAmounts);
    }
    
    
    
    


    function _consumeLogic(
        uint256 tokenId_, 
        uint256 consumeValue_, 
        address[] memory royaltyRecipients, 
        uint256[] memory royaltyAmounts
    ) internal {
        require(hasRole(SERVICE_ADMIN_ROLE, msg.sender), "Caller is not a service admin");
        

        uint256 totalUnderlyingValue = _consumeCore(tokenId_, consumeValue_);


        uint256 totalRoyaltyUnderlying = 0;
        
        if (royaltyRecipients.length > 0) {
            require(address(royaltyDistributor) != address(0), "Distributor not set");
            require(royaltyRecipients.length == royaltyAmounts.length, "Array mismatch");

            for(uint i = 0; i < royaltyAmounts.length; i++) {
                totalRoyaltyUnderlying += royaltyAmounts[i];
            }

            // Enforce 10% Cap
            require(totalRoyaltyUnderlying <= (totalUnderlyingValue * 1000) / 10000, "Royalties exceed 10%");

            if (totalRoyaltyUnderlying > 0) {
                royaltyDistributor.depositRoyalties(royaltyRecipients, royaltyAmounts);
            }
        }


        uint256 platformRevenue = totalUnderlyingValue - totalRoyaltyUnderlying;
        
        if (platformRevenue > 0) {
            require(_underlying.transfer(_revenueAddress, platformRevenue), "Revenue transfer failed");
        }

        emit CreditsConsumed(tokenId_, consumeValue_, totalUnderlyingValue, totalRoyaltyUnderlying);
    }


    function _consumeCore(uint256 tokenId_, uint256 consumeValue_) internal returns (uint256 totalUnderlyingValue) {
        require(ERC3525.balanceOf(tokenId_) >= consumeValue_, "Insufficient credit balance");

        // Calculate Backing underlying value based on RATE
        uint256 rate;
        if (isContractToken(tokenId_)) {
            rate = _countValueRate[tokenId_];
        } else {
            uint256 netTokenId = networkTokenId[tokenId_];
            rate = (netTokenId != 0) ? _slotPool.tokenValueRate(netTokenId) : _slotPool.tokenValueRate(tokenId_);
        }
        
        // Value = (Count * Rate) / Precision
        totalUnderlyingValue = (rate * consumeValue_) / (10 ** _decimals);

        // Burn Credits
        super._burnValue(tokenId_, consumeValue_);
        _totalBalance -= consumeValue_;

        // Update Solvency Ledger
        uint256 slot = ERC3525.slotOf(tokenId_);
        require(_slotUnderlyingBalance[slot] >= totalUnderlyingValue, "Insufficient slot liquidity");
        _slotUnderlyingBalance[slot] -= totalUnderlyingValue;

        return totalUnderlyingValue;
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
    	
    	require(hasRole(SERVICE_ADMIN_ROLE, msg.sender), "Caller is not a minter");
    	_underlying.transferFrom(msg.sender, address(this), paidValue_);
    	
    	uint256 tokenId;
    	
    	uint256 newRate = paidValue_ * (10 ** _decimals) / countValue_;
    	
    	if(slot_ == _defaultSlot){
    		tokenId = Service.mint(owner_, slot_, countValue_, uuid_, tokenDescription_, tokenImage_, property_);
    		
    		uint256 currentBalance = ERC3525.balanceOf(tokenId);
    		uint256 prevBalance = currentBalance - countValue_;
    		
    		// If the token existed AND had value previously, average the rate
    		if (prevBalance > 0 && _countValueRate[tokenId] > 0) {
    			uint256 oldVal = (prevBalance * _countValueRate[tokenId]);
    			uint256 newVal = (countValue_ * newRate);
    			
    			// Weighted Average: Total Value / Total Counts
    			_countValueRate[tokenId] = (oldVal + newVal) / currentBalance;
			} else {
				// It's a new token (or was empty), just set the rate
				_countValueRate[tokenId] = newRate;
			}
		} else {
			// Network Mint: Always creates a new local ID wrapper (See Service.sol logic)
			// So we can safely assign the rate without averaging
			tokenId = Service.networkMintWithValueRate(owner_, slot_, countValue_, newRate, uuid_, tokenDescription_, tokenImage_, property_);
			_countValueRate[tokenId] = newRate;
			emit MintNetworkServiceToken(networkTokenId[tokenId], slot_, countValue_);
   		}
   		
   		emit MintCountsToken(tokenId, slot_, countValue_);
   		_totalBalance += countValue_;
   		_slotUnderlyingBalance[slot_] += paidValue_;
   		return tokenId;
	}
	
  	
  	
  	

 
  	
	function redeem(uint256 tokenId_, uint256 slotId_, uint256 value_) external {
		require(ERC3525.ownerOf(tokenId_) == msg.sender || hasRole(MKT_ARBITRATOR_ROLE, msg.sender), "Sender is not authorized to redeem.");
		
		require(ERC3525.ownerOf(tokenId_) == msg.sender, "Only the owner can redeem");
		require(ERC3525.balanceOf(tokenId_) >= value_, "Insufficient credit balance");
		
		
		uint256 uValue;
		
		if (isContractToken(tokenId_)) {
	   		// Local token logic
	   		uValue = (_countValueRate[tokenId_] * value_) / (10 ** _decimals);
   		} else {
   			// Network/Pool token logic (if applicable);
   			uint256 netTokenId = networkTokenId[tokenId_];
   			uint256 rate = (netTokenId != 0) ? _slotPool.tokenValueRate(netTokenId) : _slotPool.tokenValueRate(tokenId_);
   			uValue = (rate * value_) / (10 ** _decimals);
		}
    
		
	   if(isContractToken(tokenId_)){
	       uValue =  _countValueRate[tokenId_] * value_ / (10 ** _decimals);
	   }else if(isInternalToken(tokenId_)){
	       uint256 netTokenId = networkTokenId[tokenId_];
	       if(netTokenId != 0){
	           uValue = _slotPool.tokenValueRate(netTokenId) * value_ / (10 ** _decimals); 
	       }else{
	           uValue = _slotPool.tokenValueRate(tokenId_) * value_ / (10 ** _decimals); 
	       }
	   }
	   
	   super._burnValue(tokenId_, value_);
	   _totalBalance -= value_;
	   
	   // Update Solvency Accounting
	   uint256 slot = ERC3525.slotOf(tokenId_);
	   
	   
	   // Safety check: Ensure we don't underflow (implies contract is insolvent for this slot)
	   
	   require(_slotUnderlyingBalance[slot] >= uValue, "Critical: Slot insufficient backing funds");
	   _slotUnderlyingBalance[slot] -= uValue;
	   
	   // Transfer Cash
	   
	   require(_underlying.transfer(msg.sender, uValue), "Underlying Transfer failed");
	   // emit CreditsRedeemed(msg.sender, tokenId_, value_, uValue);
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
  	
  	
  	
  	
  	function transferFrom(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_) public payable virtual override {
  	
  		// Scenario 1: Internal Transfer (Same Contract Local Tokens)
  		if(isContractToken(fromTokenId_) && isContractToken(toTokenId_)){
  			if(_countValueRate[fromTokenId_] != _countValueRate[toTokenId_]){
  				_countValueRate[toTokenId_] = calcToTokenCountValueRate(fromTokenId_, toTokenId_, value_);
  			}
  			super.transferFrom(fromTokenId_, toTokenId_, value_);
  		}
  		// Scenario 2: Network/Pool Tokens (Might involve different contracts)
  		else if(!isContractToken(fromTokenId_) && !isContractToken(toTokenId_)){
  			uint256 netTokenId = networkTokenId[fromTokenId_];
  			require(netTokenId != 0, "CountsToken: invalid sender token ID");
  			
  			// 1. Perform the Credit Transfer (ERC-3525)
  			super.transferFrom(fromTokenId_, toTokenId_, value_);
  			
  			address toContractAddress = _slotPool.contractOf(toTokenId_);
  			

  			if (toContractAddress != address(this)) {
  				uint256 countValueRate = (netTokenId != 0) ? _slotPool.tokenValueRate(netTokenId) : _slotPool.tokenValueRate(fromTokenId_);
  				uint256 uValue = countValueRate * value_ / (10 ** _decimals);
  				uint256 slot = ERC3525.slotOf(fromTokenId_);
  				
  				require(_slotUnderlyingBalance[slot] >= uValue, "Insufficient backing funds for transfer");
  				_slotUnderlyingBalance[slot] -= uValue;
  				_totalBalance -= value_; 
  				
  				require(_underlying.transfer(toContractAddress, uValue), "Underlying transfer failed");
  				
  				ILedgerUpdate(toContractAddress).addSlotLiquidity(slot, uValue);
			}
        
        	emit ValueTransfer(fromTokenId_, toTokenId_, value_);
    	} else {
        	revert("CountsCredit: transfer mismatch between local and network tokens");
    	}
	}









    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override {
        super.transferFrom( from_, to_, tokenId_);
    }
    
    function addSlotLiquidity(uint256 slotId, uint256 amount) external {
    	// Security: Ideally check that msg.sender is a valid contract in your Registry
    	require(_registry.isRegisteredContract(msg.sender), "Caller not authorized");
    	
    	 _slotUnderlyingBalance[slotId] += amount;
}
    
    
}