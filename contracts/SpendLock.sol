//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@solvprotocol/erc-3525/ERC3525.sol" as solv;



import "./SlotRegistry.sol";






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
