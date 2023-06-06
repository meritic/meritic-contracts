
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@solvprotocol/erc-3525/ERC3525.sol";
import "./ServiceMetadataDescriptor.sol";



import "./underlying/WUSDC.sol";
import "./SlotRegistry.sol";
import "./extensions/IValue.sol";







contract Service is ERC3525, Ownable {
    
    using Strings for address;
    using Strings for uint256;
    
    address private _serviceAddress;
    string private _baseuri;
    
    
    event MintServiceToken(uint256  tokenId, uint256 slot, uint256 value);
	event MetadataDescriptor(address  contractAddress);

	//IValue private _valueToken;
	

	
	TokenData[] internal _allTokens;
    mapping(uint256 => uint256) internal _allTokensIndex;
    mapping(address => AddressData) internal _addressData;

    constructor(address serviceAddress_,
        		address slotRegistry_,
        		string memory name_, 
        		string memory symbol_, 
        		string memory baseuri_,
        		string memory contractDescription_,
        		string memory contractImage_,
        		//address valueTokenContractAddress_,
        		uint8 decimals_) ERC3525(name_, symbol_, decimals_) {
        		    
        		//string memory valueToken_ = "USDC";

        _serviceAddress = serviceAddress_;
  		_baseuri = baseuri_;
  		
        metadataDescriptor = new ServiceMetadataDescriptor(_baseuri, contractDescription_, contractImage_, slotRegistry_);
        
        
        //if( keccak256(bytes(valueToken_)) == keccak256(bytes("USDC")) ){
        //    _valueToken = WUSDC(valueTokenContractAddress_); 
        //}
        
        emit MetadataDescriptor(address(metadataDescriptor));
    }
    
    
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseuri;
    }
    
    
 	function _setBaseURI(string memory uri_) external virtual {
        _baseuri = uri_;
        ServiceMetadataDescriptor(address(metadataDescriptor)).setBaseURI(uri_);
    }
 
 	
	
    function mint(address owner_, 
        			uint256 slot_, 
        			uint256 value_,
        			string memory uuid_,
        			string memory token_description_,
        			string memory token_image_
    ) public virtual onlyOwner returns (uint256) {
        
        uint256 tokenId = _createOriginalTokenId();
        
        //_valueToken.mint(value_, address(this));
        
        super._mint(owner_, tokenId, slot_, value_);
        
        TokenData memory tokenData = TokenData({
            id: tokenId,
            slot: slot_,
            balance: value_,
            owner: owner_,
            approved: address(0),
            valueApprovals: new address[](0)
        });

        _addTokenToAllTokensEnum(tokenData);
        _addTokenToOwnerEnum(owner_, tokenId);
    
    	ServiceMetadataDescriptor(address(metadataDescriptor)).setTokenUUID(tokenId, uuid_);
    	ServiceMetadataDescriptor(address(metadataDescriptor)).setTokenDescription(tokenId, token_description_);
    	ServiceMetadataDescriptor(address(metadataDescriptor)).setTokenImage(tokenId, token_image_);
    	
        emit MintServiceToken(tokenId, slot_, value_);

	    return tokenId;
  	}
  
  
  
  function setApprovalForAll(address operator_, bool approved_) public virtual override {
        super.setApprovalForAll(operator_, approved_);
        /** CHECK THAT APPROVAL WAS SUCCESSFUL **/
        _addressData[_msgSender()].approvals[operator_] = approved_;
    }

    
    
    
    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override returns (uint256) {
        return super.transferFrom(fromTokenId_, to_, value_);
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
    
    
    
    
    
    
    
    function _addTokenToOwnerEnum(address to_, uint256 tokenId_) private {
        _allTokens[_allTokensIndex[tokenId_]].owner = to_;
        _addressData[to_].ownedTokensIndex[tokenId_] = _addressData[to_].ownedTokens.length;
        _addressData[to_].ownedTokens.push(tokenId_);
    }





    function _removeTokenFromOwnerEnum(address from_, uint256 tokenId_) private {
        _allTokens[_allTokensIndex[tokenId_]].owner = address(0);

        AddressData storage ownerData = _addressData[from_];
        uint256 lastTokenIndex = ownerData.ownedTokens.length - 1;
        uint256 lastTokenId = ownerData.ownedTokens[lastTokenIndex];
        uint256 tokenIndex = ownerData.ownedTokensIndex[tokenId_];

        ownerData.ownedTokens[tokenIndex] = lastTokenId;
        ownerData.ownedTokensIndex[lastTokenId] = tokenIndex;

        delete ownerData.ownedTokensIndex[tokenId_];
        ownerData.ownedTokens.pop();
    }



    function _addTokenToAllTokensEnum(TokenData memory tokenData_) private {
        _allTokensIndex[tokenData_.id] = _allTokens.length;
        _allTokens.push(tokenData_);
    }
    
    

    function _removeTokenFromAllTokensEnum(uint256 tokenId_) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId_];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        TokenData memory lastTokenData = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenData; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenData.id] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId_];
        _allTokens.pop();
    }
    

    /*function burn(uint256 tokenId_) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: transfer caller is not owner nor approved");
       	_burn(tokenId_);
      	//uint256 locId = _spendLock[tokenId_];
      	
      	/*lockGenerator.burn(locId);
      	delete _spendLock[tokenId_];
      	* 
      	*
    }*/
    
    


    
    
   /* function tokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual payable {
        require(super._isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: transfer caller is not owner nor approved");
        //uint256 lockId = _spendLock[tokenId_];
        //address lockHolder = lockOwner(lockId);
        //require(lockHolder == from_, "ERC3525: cannot transfer a token without a lock");
        
        super.safeTransferFrom(from_, to_, tokenId_);
        
        
    }*/
    


}