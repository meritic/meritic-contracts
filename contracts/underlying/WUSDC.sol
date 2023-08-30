//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../extensions/Underlying.sol";





contract WUSDC is ERC20("Wrapped USDC", "WUSDC"), Underlying, AccessControl {
    

    ERC20 private usdc;
    
	mapping(uint256 => mapping(address => uint256)) private _slotApprovedValues;
	
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





    
    
    
    function redeem(address to_, uint256 slotId_, uint256 amount_) external {
        _redeem(to_, slotId_, amount_);
    }
    
    
    
    
    function _redeem(address to_, uint256 slotId_, uint256 amount_) private {
        if(amount_ <= _slotApprovedValues[slotId_][msg.sender]){
            _burn(msg.sender, amount_); 
	        usdc.approve(to_, amount_);
	        usdc.transfer(to_, amount_);
	        
	        _slotApprovedValues[slotId_][msg.sender] -= amount_;
        }
        emit Redeem(msg.sender, amount_);
    }
    
    
	function mint(address to_, uint256 slotId_, uint256 amount_) external  {
        _mint(to_, amount_);
        _slotApprovedValues[slotId_][msg.sender] += amount_;
        emit MintWUSDC(msg.sender, to_, amount_);
    }

    function _mint(address to, uint256 amount) internal override {
        usdc.approve(to, amount);
   		usdc.transfer(to, amount); 
   		super._mint(to, amount); 
    }
    
    

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(hasRole(TRANSFER_ADMIN_ROLE, from), "WUSDC: Transfer refused. Unauthorized account");
        
        usdc.approve(to, amount);
        usdc.transfer(to, amount); 
        return super.transferFrom(from,  to,  amount);
    }
    
    function transfer(address to, uint256 amount) public virtual override (ERC20, Underlying) returns (bool) {
        bool result = super.transfer(to, amount);
        usdc.approve(to, amount);
        usdc.transfer(to, amount); 
        return result;
        
    }

}


