//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
//import "./ERC20.sol";
//import "../../utils/SafeTransferLib.sol";

import "../extensions/IValue.sol";





contract WUSDC is ERC20("Wrapped USDC", "WUSDC"), IValue, AccessControl {
    
   // using SafeTransferLib for address;

    ERC20 private usdc;

    /// @notice emitted on mint, minter is address(this)
    event MintWUSDC(address indexed minter, address indexed to, uint256 amount);
    bytes32 public constant TRANSFER_ADMIN_ROLE = keccak256("TRANSFER_ADMIN_ROLE");
    
    constructor(address usdcContract_, address mktAdminAcct_){
        usdc = ERC20(usdcContract_); 
        _setupRole(TRANSFER_ADMIN_ROLE, mktAdminAcct_);
    }
    
    
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
    
    /// @notice emitted on redeem, redeemer is msg.sender
    event Redeem(address indexed redeemer, uint256 amount);





    function mint(address to, uint256 amount) external payable {
        _mint(to, amount);
        emit MintWUSDC(msg.sender, to, amount);
    }
    
    
    function redeem(address to, uint256 amount) external payable{
        _redeem(to, amount);
    }
    
    
    
    
    function _redeem(address to, uint256 amount) private {
        _burn(msg.sender, amount); /// subtract internal balance first
        usdc.approve(to, amount);
        usdc.transfer(to, amount); /// pay out USDC

        emit Redeem(msg.sender, amount);
    }
    
    


    function _mint(address to, uint256 amount) internal override {
        usdc.approve(to, amount);
   		usdc.transfer(to, amount); 
   		super._mint(to, amount); /// mint WUSD
    }
    
    

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(hasRole(TRANSFER_ADMIN_ROLE, from), "WUSDC: Transfer refused. Unauthorized account");
        
        usdc.approve(to, amount);
        usdc.transfer(to, amount); 
        return super.transferFrom(from,  to,  amount);
    }
    
    function transfer(address to, uint256 amount) public virtual override (ERC20, IValue) returns (bool) {
        require(hasRole(TRANSFER_ADMIN_ROLE, msg.sender), "WUSDC: Transfer refused. Unauthorized account");
        bool result = super.transfer(to, amount);
        usdc.approve(to, amount);
        usdc.transfer(to, amount); 
        return result;
        
    }

}


