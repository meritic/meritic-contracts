
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


interface IPool {
    function poolToken(uint256 slotId_, uint256 tokenId_) external;
    function contractOf(uint256 networkTokenId_) external view returns (address);
    function tokenDiscount(uint256 tokenId_) external view returns (uint256);
}





contract CashCredit is Service, ILedgerUpdate {
    

	IPool internal _poolContract;
	
	
	uint256 _decimals;

	uint256 _totalBalance;
	uint256 internal _hundredPctMilliBasisPts = 10000 * 1000;
	mapping(uint256 => uint256) private _tokenDiscount;

	mapping(uint256 => uint256) internal _slotUsdcBalance;
	
	event MintNetworkServiceToken(uint256  tokenId, uint256 slot, uint256 value);
	event MintCashToken(uint256  tokenId, uint256 slot, uint256 value);
	event RedeemForAsset(uint256  tokenId, address indexed redeemer, uint256 amount);
	event RedeemForAccess(address indexed redeemer, uint256 creditAmount, uint256 valueAmount );
	
	IERC20 internal _usdc;

    constructor(address revenueAcct_,
        		address slotRegistryContract_,
        		address poolContract_,
        		address usdcContract_,
        		address mktAdmin_,
        		uint256 defaultSlot_,
        		string memory name_, 
        		string memory symbol_, 
        		string memory baseuri_,
        		string memory contractDescription_,
        		string memory contractImage_,
        		uint8 decimals_) Service(revenueAcct_, mktAdmin_, slotRegistryContract_, poolContract_, defaultSlot_, name_, symbol_ , baseuri_, contractDescription_, contractImage_, 'cash', decimals_) {
        		
       	_usdc = IERC20(usdcContract_); 
        _decimals = decimals_;
        _poolContract = IPool(poolContract_);

    }
    
    
    
    

 
 
 	
    function mintWithDiscount(address owner_, 
        			uint256 slot_, 
        			uint256 value_, // The Face Value of the credit (e.g., $100 voucher)
        			uint256 discountBasisPts_, // The discount (e.g., 10% off)
        			string memory uuid_,
        			string memory tokenDescription_,
        			string memory tokenImage_,
        			string memory property_
    ) public virtual returns (uint256) {
    
    	uint256 uValue = (_hundredPctMilliBasisPts - discountBasisPts_ / (10 ** _decimals)) * value_ / _hundredPctMilliBasisPts;
    	_usdc.transferFrom(msg.sender, address(this), uValue);
    	
    	uint256 tokenId;
    	
    	if(slot_ == _defaultSlot){
    		// Local Mint (Utilizes Service.sol Smart Minting)
    		tokenId = Service.mint(owner_, slot_, value_, uuid_, tokenDescription_, tokenImage_, property_);
      
       		uint256 currentBalance = ERC3525.balanceOf(tokenId);
       		uint256 prevBalance = currentBalance - value_;
       		
       		if (prevBalance > 0) {
       			// Token existed. We must blend the discount so backing value remains correct.
       			// Formula: (OldFace * OldDiscount + NewFace * NewDiscount) / TotalFace
       			uint256 oldDiscount = _tokenDiscount[tokenId];
       			uint256 weightedDiscount = ((prevBalance * oldDiscount) + (value_ * discountBasisPts_)) / currentBalance;
       			_tokenDiscount[tokenId] = weightedDiscount;
   			} else {
   				// New Token
   				_tokenDiscount[tokenId] = discountBasisPts_;
			}
		} else {
			// Network Mint
			// Service.networkMintWithDiscount usually creates a fresh token ID
			tokenId = Service.networkMintWithDiscount(owner_, slot_, value_, discountBasisPts_, uuid_, tokenDescription_, tokenImage_, property_);
			// For network tokens, assume fresh ID, so set discount directly
			_tokenDiscount[tokenId] = discountBasisPts_;
			emit MintNetworkServiceToken(networkTokenId[tokenId], slot_, value_);
		}
		
		_registry.registerTokenSlot(tokenId, slot_);
		
		if(slot_ != _defaultSlot){
			_poolContract.poolToken(slot_, tokenId);
		}
		
		emit MintCashToken(tokenId, slot_, value_);
		_totalBalance += value_;
		
		_slotUsdcBalance[slot_] += uValue;
		
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
    	return mintWithDiscount(owner_, slot_, value_, 0, uuid_, tokenDescription_, tokenImage_, property_);
    	
  	}
  	
  	
  	
  	function tokenDiscount(uint256 tokenId_) external view returns (uint256) {
        if(isContractToken(tokenId_)){
            return _tokenDiscount[tokenId_];    
        } else {
            return _poolContract.tokenDiscount(tokenId_);
        }
    }
    
    
    
    function redeem(uint256 tokenId_, uint256 value_) external {
        require(ERC3525.ownerOf(tokenId_) == msg.sender, "Sender not authorized to redeem.");
        require(ERC3525.balanceOf(tokenId_) >= value_, "Insufficient credit balance");

        // 1. Calculate Backing Value
        uint256 discount;
        if(isContractToken(tokenId_)){
            discount = _tokenDiscount[tokenId_];
        } else {
            uint256 netTokenId = networkTokenId[tokenId_];
            discount = (netTokenId != 0) ? _poolContract.tokenDiscount(netTokenId) : _poolContract.tokenDiscount(tokenId_);
        }

        uint256 uValue = (_hundredPctMilliBasisPts - discount / (10 ** _decimals)) * value_ / _hundredPctMilliBasisPts;

        super._burnValue(tokenId_, value_);
        _totalBalance -= value_;

        // 3. Update Ledger & Transfer
        uint256 slot = ERC3525.slotOf(tokenId_);
        require(_slotUsdcBalance[slot] >= uValue, "Critical: Slot insolvent");
        
        _slotUsdcBalance[slot] -= uValue;
        
        require(_usdc.transfer(msg.sender, uValue), "USDC Transfer failed");
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
       
       require(_slotUsdcBalance[slotId_] >= uValue, "Insufficient slot liquidity");
       
       // Approve Offering contract to pull USDC
       _usdc.approve(offeringContract_, uValue);
       
       // This returns the Token ID of the purchased Asset (e.g., Access Pass or Item)
       uint256 assetTokenId = offering.mintFromCredits( 
                                                address(this), 
                                                creditTokenId_, 
                                                discount, 
                                                msg.sender, 
                                                slotId_, 
                                                value_, 
                                                assetId_);
                                                
       _slotUsdcBalance[slotId_] -= uValue;
       _totalBalance -= value_;
       
       super._burnValue(creditTokenId_, value_);
       
       emit RedeemForAsset(assetTokenId, msg.sender, uValue);
       return assetTokenId;
    }
    
    
    
	
	
	
	
	
	
	
	function addSlotLiquidity(uint256 slotId, uint256 amount) external override {
        // Only accept liquidity updates, usually from trusted contracts
        _slotUsdcBalance[slotId] += amount;
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
            
            address toContractAddress = _poolContract.contractOf(toTokenId_);
            
            // Perform Credit Transfer
            super.transferFrom(fromTokenId_, toTokenId_, value_);
            
            // If target is another contract, move funds and notify
            if (toContractAddress != address(this)) {
                
                uint256 discount = (netTokenId != 0) ? _poolContract.tokenDiscount(netTokenId) : _poolContract.tokenDiscount(fromTokenId_);
                uint256 uValue = (_hundredPctMilliBasisPts - discount / (10 ** _decimals)) * value_ / _hundredPctMilliBasisPts;
                
                uint256 slot = ERC3525.slotOf(fromTokenId_);

                require(_slotUsdcBalance[slot] >= uValue, "Insufficient liquidity for transfer");
                _slotUsdcBalance[slot] -= uValue;
                _totalBalance -= value_;

                require(_usdc.transfer(toContractAddress, uValue), "USDC transfer failed");

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