
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;



import "./Service.sol";








contract SpendCredit is Service {
    

	IValue private _valueToken;
	

    constructor(address serviceAddress_,
        		address slotRegistry_,
        		string memory name_, 
        		string memory symbol_, 
        		string memory baseuri_,
        		string memory contractDescription_,
        		string memory contractImage_,
        		string memory valueToken_,
        		address valueTokenContractAddress_,
        		uint8 decimals_) Service(serviceAddress_, slotRegistry_, name_, symbol_, baseuri_, contractDescription_, contractImage_,  decimals_) {

        if( keccak256(bytes(valueToken_)) == keccak256(bytes("USDC")) ){
            _valueToken = WUSDC(valueTokenContractAddress_); 
        }
        
    }
    

 
 
 	
	
    function mint(address owner_, 
        			uint256 slot_, 
        			uint256 value_,
        			string memory uuid_,
        			string memory token_description_,
        			string memory token_image_
    ) public  virtual override returns (uint256) {
 
        //uint256 tokenId = _createOriginalTokenId();
       _valueToken.mint(value_, address(this));
        
       uint256 tokenId = super.mint(owner_, slot_, value_, uuid_, token_description_, token_image_);

	   return tokenId;
  	}
  
  
  
  
  
  
  
  
  
  
   /*function setApprovalForAll(address operator_, bool approved_) public virtual override {
        super.setApprovalForAll(operator_, approved_);
        
        _addressData[_msgSender()].approvals[operator_] = approved_;
    }*/

    
    
    
    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override returns (uint256) {
        return super.transferFrom(fromTokenId_, to_, value_);
        //address fromOwnerAddress = _allTokens[_allTokensIndex[fromTokenId_]].owner;
    }

    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable virtual override {
        super.transferFrom(fromTokenId_, toTokenId_, value_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override {
        super.transferFrom( from_, to_, tokenId_);
    }
    
    

    


}