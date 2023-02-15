
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@solvprotocol/erc-3525/ERC3525.sol" as solv;



import "./SlotRegistry.sol";




/* 
contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}
*/







contract SpendLock is ERC721, Ownable {
    
    using Counters for Counters.Counter;
    
    Counters.Counter private _nextTokenId;
    
    address private _lockAdminAddress;
    
    constructor(string memory name_, string memory symbol_, address meriticLockAdminAddress_) ERC721(name_, symbol_) {
        _lockAdminAddress = meriticLockAdminAddress_;
    }
    

	function isApprovedForAll(address _owner, address _operator) override public view returns (bool isOperator) {

	    /*ProxyRegistry proxyRegistry = ProxyRegistry(_lockAdminAddress);
	    if (address(proxyRegistry.proxies(_owner)) == _operator) {
	      return true;
	    }*/
	    
	    return super.isApprovedForAll(_owner, _operator);
	}
	
	
	
	function mintTo(address _to) public onlyOwner returns (uint256){
	    _nextTokenId.increment();
        uint256 currentTokenId = _nextTokenId.current();
        _safeMint(_to, currentTokenId);
        _setApprovalForAll(_to, _msgSender(), true);
        return currentTokenId;
    }
    
    
    function transferToken(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable {
        
        super.safeTransferFrom(from_, to_, tokenId_);
    }
    
    
    
    
    
    
    function burn(uint256 tokenId_) public onlyOwner {
 
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "SpendLock: transfer caller is not owner nor approved");
        super._burn(tokenId_);
    }
    
    
    
    
    function owner() public view override returns (address) {
        return super.owner();
    }
    
    function msgSender() public view returns (address) {
        return _msgSender();
    }
    
   
}






contract Service is solv.ERC3525, Ownable {
    
    using Strings for address;
    using Strings for uint256;
    
    address private _serviceOwner;
    address private _proxyRegistryAddress;
    
    SlotRegistry sr;
    SpendLock private lockGenerator; 
    


        
    mapping (uint256 => uint256) private _spendLock;
    
    event MintServiceToken(uint256  _tokenId);

    
    constructor(address serviceOwner_, 
        		address proxyAddress_,
        		address slotRegistry_, 
        		address lockAdmin_, string memory name_, string memory symbol_) solv.ERC3525(name_, symbol_, 18) {
        		    
        _serviceOwner = serviceOwner_;
        _proxyRegistryAddress = proxyAddress_;
        sr = SlotRegistry(slotRegistry_);
        lockGenerator = new SpendLock(string(abi.encodePacked('LOCKS FOR: ', name_, '(', symbol_, ')')), string(abi.encodePacked('LOCK:', symbol_)), lockAdmin_);   
    }
    
    
    
   
	function isApprovedForAll(address _owner, address _operator) override public view returns (bool isOperator) {

	    /*ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
	    if (address(proxyRegistry.proxies(_owner)) == _operator) {
	      return true;
	    }*/
	    
	    return super.isApprovedForAll(_owner, _operator);
	}
	

	function slotURI(uint256 slot_) public view override returns (string memory) {
        return sr.slotURI(slot_); 
    }
	





    function create(address _initialOwner, uint256 slot_, uint256 initialValue_ /*, string memory _uri */) public onlyOwner returns (uint256) {
        uint256 tokenId = _createOriginalTokenId();
        _mint(_initialOwner, tokenId, slot_, initialValue_);
        uint256 lockId = lockGenerator.mintTo(_initialOwner);
       	_spendLock[tokenId] = lockId;

	    return tokenId;
  	}
  
  

    
    
    
    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable override returns (uint256) {
        uint256 newTokenId = solv.ERC3525.transferFrom(fromTokenId_, to_, value_);
  
        uint256 lockId = lockGenerator.mintTo(to_);
       	_spendLock[newTokenId] = lockId;
       	emit MintServiceToken(newTokenId);
       	
       	
       	return newTokenId;
    }
    
    
    
    
    
    
    function burn(uint256 tokenId_) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: transfer caller is not owner nor approved");
       	_burn(tokenId_);
      	uint256 locId = _spendLock[tokenId_];
      	lockGenerator.burn(locId);
      	delete _spendLock[tokenId_];
    }
    
    
    function ownedTokens(address userAddr_, uint256 index_) public view returns (uint256) {
        require(userAddr_ != address(0), "ERC3525: cannot get data for 0 address");
        return super.tokenOfOwnerByIndex(userAddr_, index_); //[userAddr_].ownedTokens.length;

        
    }
    

    
    function getLockId(uint256 tokenId_) public view returns (uint256) {
        
        uint256 lid = _spendLock[tokenId_];
        return lid;
    }
    

    
    function lockOwner(uint256 lockId_) public view returns (address){
        return lockGenerator.ownerOf(lockId_);
    }
    
    
    function tokenOwner(uint256 tokenId_) public view returns (address){
        return ownerOf(tokenId_);
    }
    
    
    
    function tokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable {
        // ERC721: transfer to non ERC721Receiver implementer
        require(super._isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: transfer caller is not owner nor approved");
        uint256 lockId = _spendLock[tokenId_];
        address lockHolder = lockOwner(lockId);
        require(lockHolder == from_, "ERC3525: cannot transfer a token without a lock");
        
        super.safeTransferFrom(from_, to_, tokenId_);
        
        if(from_ != address(this)){
            lockGenerator.safeTransferFrom(from_, to_, lockId);
        }
    }


    function lockMsgSender() public view returns (address) {
        return lockGenerator.msgSender();
    }
    
    
 


}