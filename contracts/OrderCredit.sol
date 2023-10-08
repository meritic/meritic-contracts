//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;



import "./Service.sol";








contract OrderCredit is Service {
    

	uint256[] private _tokenQ; 
	
	

        		
    constructor(address revenueAddress_,
        		address adminAddress_,
        		address slotRegistry_,
        		address mktAdmin_,
        		uint256 defaultSlot_,
        		string memory name_, 
        		string memory symbol_, 
        		string memory baseUri_,
        		string memory contractDescription_,
        		string memory contractImage_,
        		uint8 decimals_) Service(adminAddress_, mktAdmin_, slotRegistry_, defaultSlot_, name_, symbol_ , baseUri_, contractDescription_ , contractImage_, 'priority', decimals_) {

    }
    

 
 
 	
	
    function mint(address owner_, 
        			uint256 slot_, 
        			uint256 value_,
        			string memory uuid_,
        			string memory tokenDescription_,
        			string memory tokenImage_,
        			string memory property_
    ) public virtual override returns (uint256) {
        require(value_ == totalSupply(), 'OrderCredit: New tokens can only mint to the end of the list');
        uint256 tokenId = Service.mint(owner_, slot_, value_, uuid_, tokenDescription_, tokenImage_, property_);
		_tokenQ.push(tokenId);
	   return tokenId;
  	}
  	
  	
  	function enqueue(address owner_, 
        			uint256 slot_, 
        			string memory uuid_,
        			string memory tokenDescription_,
        			string memory tokenImage_,
        			string memory property_) public virtual returns (uint256) {
    	uint256 position = totalSupply();
    	
    	return mint(owner_, slot_, position, uuid_, tokenDescription_, tokenImage_, property_);
    }
  	
  	
  	function dequeue(uint256 index) public virtual{
  	    uint256 n = totalSupply();
  	    require(n > 0, 'OrderCredit: List is empty');
  	    super._burn(_tokenQ[index]);

  	    uint i = 0;
  	    
  	    for(i = index; i < n; ++i){
  	       if(i + 1 < n){
  	           _mintValue(_tokenQ[i + 1], 1);
  	           _tokenQ[i] = _tokenQ[i + 1] ;
  	       }
  	    }
  	}
  	
  	

    
    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override returns (uint256) {
        require(value_ == balanceOf(fromTokenId_), 'OrderCredit: only entire value can be transfered');
        uint256 newTokenId = super.transferFrom(fromTokenId_, to_, value_);
        _tokenQ[value_] = newTokenId;
        super._burn(fromTokenId_);       
        return   newTokenId;
    }




    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable virtual override {
        require(value_ == balanceOf(fromTokenId_), 'OrderCredit: only entire value can be transfered');
        uint256 toValue_ = balanceOf(toTokenId_); 
        _burnValue(toTokenId_, toValue_);
        super.transferFrom(fromTokenId_, toTokenId_, value_);
        super.transferFrom(toTokenId_, fromTokenId_, toValue_);
    }



    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override {
        super.transferFrom(from_, to_, tokenId_);
    }
    
    
    
    
}