
//SPDX-License-Identifier: 	BUSL-1.1
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Service.sol";
import "./interfaces/ILedgerUpdate.sol"; 







interface IOffering {
    function isApproveCredit(address creditContract_) external view returns (bool);
    function approveCredit(address creditContract_) external;
    
    function mintFromCredits(
        address creditContract_, 
        uint256 creditTokenId_,
        uint256 discountMilliBasisPts_,
        address owner_, 
        uint256 slotId_,
        uint256 value_,
        string memory offeringAssetId_
    ) external returns (uint256);

    function accessFromCredits(
        address creditContract_, 
        uint256 creditTokenId_, 
        uint256 creditSlotId_, 
        uint256 discountMilliBasisPts_, 
        string memory offeringAssetId_, 
        uint256 value_, 
        uint256 endTime_
    ) external returns (bool);
}







contract CashCredit is Service, ILedgerUpdate {
    

	uint256 _totalBalance;
	uint256 internal _hundredPctMilliBasisPts = 10000 * 1000;
	mapping(uint256 => uint256) private _tokenDiscount;

	mapping(uint256 => uint256) internal _slotUnderlyingBalance;
	
	event MintCashToken(uint256  tokenId, uint256 slot, uint256 value);

	
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
        		uint8 decimals_) Service(revenueAcct_, mktAdmin_, slotRegistryContract_, poolContract_, underlyingContract_,  defaultSlot_, name_, symbol_ , baseuri_, contractDescription_, contractImage_, 'cash', decimals_)
    { }
    
    
    
    
    
  
    
    
    function _consumeCore(uint256 tokenId_, uint256 consumeValue_) internal returns (uint256 totalUnderlyingValue) {
        require(ERC3525.balanceOf(tokenId_) >= consumeValue_, "Insufficient credit balance");

        uint256 discount;
        if(isContractToken(tokenId_)){
            discount = _tokenDiscount[tokenId_];
        } else {
            uint256 netTokenId = networkTokenId[tokenId_];
            discount = (netTokenId != 0) ? _slotPool.tokenDiscount(netTokenId) : _slotPool.tokenDiscount(tokenId_);
        }

        totalUnderlyingValue = (_hundredPctMilliBasisPts - discount / (10 ** _decimals)) * consumeValue_ / _hundredPctMilliBasisPts;

        super._burnValue(tokenId_, consumeValue_);
        _totalBalance -= consumeValue_;

        uint256 slot = ERC3525.slotOf(tokenId_);
        require(_slotUnderlyingBalance[slot] >= totalUnderlyingValue, "Insufficient slot liquidity");
        _slotUnderlyingBalance[slot] -= totalUnderlyingValue;

        return totalUnderlyingValue;
    }
    
    
    function consumeCredits(uint256 tokenId_, uint256 consumeValue_) external {
        _consumeLogic(tokenId_, consumeValue_, new address[](0), new uint256[](0));
    }
    
    function consumeWithRoyalties(
        uint256 tokenId_, 
        uint256 consumeValue_, 
        address[] calldata royaltyRecipients, 
        uint256[] calldata royaltyAmounts
    ) external {
        _consumeLogic(tokenId_, consumeValue_, royaltyRecipients, royaltyAmounts);
    }
    
    
    
    function _consumeLogic(
        uint256 tokenId_, 
        uint256 consumeValue_, 
        address[] memory royaltyRecipients, 
        uint256[] memory royaltyAmounts
    ) internal {
        require(hasRole(SERVICE_ADMIN_ROLE, msg.sender), "Caller is not a service admin");
        
        // --- CORE BURN & SOLVENCY CHECK ---
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
    
    
    
    

 
 	/**
     * @notice Mints a CashCredit token by specifying Face Value and Amount Paid.
     * @dev Calculates the discount automatically.
     * @param owner_ Recipient
     * @param slot_ Slot ID
     * @param faceValue_ The amount of Credits the user sees (e.g. 100.00)
     * @param paidValue_ The amount of Underlying actually paid (e.g. 90.00)
     */
    function mintCash(
        address owner_, 
        uint256 slot_, 
        uint256 faceValue_, 
        uint256 paidValue_, 
        string memory uuid_,
        string memory tokenDescription_,
        string memory tokenImage_,
        string memory property_
    ) public virtual returns (uint256) {
    
        require(hasRole(SERVICE_ADMIN_ROLE, msg.sender), "Caller is not a minter");
        
        uint256 discountBasisPts = 0;
        if (faceValue_ > 0) {
            discountBasisPts = ((faceValue_ - paidValue_) * _hundredPctMilliBasisPts) / faceValue_;
        }

        _underlying.transferFrom(msg.sender, address(this), paidValue_);
        
        uint256 tokenId;
        
        if(slot_ == _defaultSlot){
            tokenId = Service.mint(owner_, slot_, faceValue_, uuid_, tokenDescription_, tokenImage_, property_);
            
            // Weighted Average Logic
            uint256 currentBalance = ERC3525.balanceOf(tokenId);
            uint256 prevBalance = currentBalance - faceValue_;

            if (prevBalance > 0) {
                uint256 oldDiscount = _tokenDiscount[tokenId];
                uint256 weightedDiscount = ((prevBalance * oldDiscount) + (faceValue_ * discountBasisPts)) / currentBalance;
                _tokenDiscount[tokenId] = weightedDiscount;
            } else {
                _tokenDiscount[tokenId] = discountBasisPts;
            }
        } else {
            tokenId = Service.networkMintWithDiscount(owner_, slot_, faceValue_, discountBasisPts, uuid_, tokenDescription_, tokenImage_, property_);
            _tokenDiscount[tokenId] = discountBasisPts;
            emit MintNetworkServiceToken(networkTokenId[tokenId], slot_, faceValue_);
        }
        
        _registry.registerTokenSlot(tokenId, slot_); 

        emit MintCashToken(tokenId, slot_, faceValue_);
        _totalBalance += faceValue_;
        
        _slotUnderlyingBalance[slot_] += paidValue_;
        
        return tokenId;
    }
    
    
    
    function mint(
        address owner_, 
        uint256 slot_, 
        uint256 value_, 
        string memory uuid_,
        string memory tokenDescription_,
        string memory tokenImage_,
        string memory property_
    ) public virtual override returns (uint256) {
    
        return mintCash(owner_, slot_, value_, value_, uuid_, tokenDescription_, tokenImage_, property_);
        
    }
  	
  	
  	
  	function tokenDiscount(uint256 tokenId_) external view returns (uint256) {
        if(isContractToken(tokenId_)){
            return _tokenDiscount[tokenId_];    
        } else {
            return _slotPool.tokenDiscount(tokenId_);
        }
    }
    
    
    
    function redeem(uint256 tokenId_, uint256 value_) external {
        require(ERC3525.ownerOf(tokenId_) == msg.sender, "Sender not authorized to redeem.");
        require(ERC3525.balanceOf(tokenId_) >= value_, "Insufficient credit balance");

        // 1. Calculate Underlying Value
        uint256 discount;
        if(isContractToken(tokenId_)){
            discount = _tokenDiscount[tokenId_];
        } else {
            uint256 netTokenId = networkTokenId[tokenId_];
            discount = (netTokenId != 0) ? _slotPool.tokenDiscount(netTokenId) : _slotPool.tokenDiscount(tokenId_);
        }

        uint256 uValue = (_hundredPctMilliBasisPts - discount / (10 ** _decimals)) * value_ / _hundredPctMilliBasisPts;

        super._burnValue(tokenId_, value_);
        _totalBalance -= value_;

        // 3. Update Ledger & Transfer
        uint256 slot = ERC3525.slotOf(tokenId_);
        require(_slotUnderlyingBalance[slot] >= uValue, "Critical: Slot insolvent");
        
        _slotUnderlyingBalance[slot] -= uValue;
        
        require(_underlying.transfer(msg.sender, uValue), "Underlying Transfer failed");
    }
    
    
    
    
    
    function redeemForAsset(
        address offeringContract_, 
        uint256 creditTokenId_, 
        uint256 slotId_, 
        uint256 value_,
        string memory assetId_
    ) external returns (uint256) {
       
       IOffering offering = IOffering(offeringContract_);
       
       require(ERC3525.ownerOf(creditTokenId_) == msg.sender || _registry.hasAccess('MKT_ADMIN', msg.sender), "Sender is not authorized.");
       require(ERC3525.balanceOf(creditTokenId_) >= value_, 'Value exceeds credit balance');
       
       if(!offering.isApproveCredit(address(this))){
           offering.approveCredit(address(this));
       }
       
       uint256 discount = _tokenDiscount[creditTokenId_];
       uint256 uValue = (_hundredPctMilliBasisPts - discount / (10 ** _decimals)) * value_ / _hundredPctMilliBasisPts;
       
       require(_slotUnderlyingBalance[slotId_] >= uValue, "Insufficient slot liquidity");
       
       // Approve Offering contract to pull Underlying
       _underlying.approve(offeringContract_, uValue);
       
       // This returns the Token ID of the purchased Asset (e.g., Access Pass or Item)
       uint256 assetTokenId = offering.mintFromCredits( 
                                                address(this), 
                                                creditTokenId_, 
                                                discount, 
                                                msg.sender, 
                                                slotId_, 
                                                value_, 
                                                assetId_);
                                                
       _slotUnderlyingBalance[slotId_] -= uValue;
       _totalBalance -= value_;
       
       super._burnValue(creditTokenId_, value_);
       
       emit RedeemForAsset(assetTokenId, msg.sender, uValue);
       return assetTokenId;
    }
    
    
    
	
	
	
	
	
	
	
	function addSlotLiquidity(uint256 slotId, uint256 amount) external override {
        // Only accept liquidity updates, usually from trusted contracts
        _slotUnderlyingBalance[slotId] += amount;
    }
    

	function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable virtual override {
        
        // Scenario 1: Same Contract Transfer
        if(isContractToken(fromTokenId_) && isContractToken(toTokenId_)){
            
            uint256 toTokenValue = ERC3525.balanceOf(toTokenId_);
            uint256 fromDiscount = _tokenDiscount[fromTokenId_];
            uint256 toDiscount = _tokenDiscount[toTokenId_];

            if(fromDiscount != toDiscount){
                // Weighted Average Discount
                _tokenDiscount[toTokenId_] = ((fromDiscount * value_) + (toDiscount * toTokenValue)) / (value_ + toTokenValue);
            }
            super.transferFrom(fromTokenId_, toTokenId_, value_);
            
        } 
        // Scenario 2: Network Transfer (Cross-Contract)
        else if(!isContractToken(fromTokenId_) && !isContractToken(toTokenId_)){
            
            uint256 netTokenId = networkTokenId[fromTokenId_];
            require(netTokenId != 0, "CashCredit: invalid sender token ID");
            
            address toContractAddress = _slotPool.contractOf(toTokenId_);
            
            // Perform Credit Transfer
            super.transferFrom(fromTokenId_, toTokenId_, value_);
            
            // If target is another contract, move funds and notify
            if (toContractAddress != address(this)) {
                
                uint256 discount = (netTokenId != 0) ? _slotPool.tokenDiscount(netTokenId) : _slotPool.tokenDiscount(fromTokenId_);
                uint256 uValue = (_hundredPctMilliBasisPts - discount / (10 ** _decimals)) * value_ / _hundredPctMilliBasisPts;
                
                uint256 slot = ERC3525.slotOf(fromTokenId_);

                require(_slotUnderlyingBalance[slot] >= uValue, "Insufficient liquidity for transfer");
                _slotUnderlyingBalance[slot] -= uValue;
                _totalBalance -= value_;

                require(_underlying.transfer(toContractAddress, uValue), "Underlying transfer failed");

                ILedgerUpdate(toContractAddress).addSlotLiquidity(slot, uValue);
            }
            
        } else {
            revert("CashCredit: transfer type mismatch");
        }
    }
    
    
    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override returns (uint256) {
        return super.transferFrom(fromTokenId_, to_, value_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override {
        super.transferFrom( from_, to_, tokenId_);
    }

    function totalBalance() public view returns (uint256){
        return _totalBalance;
    }
    

}