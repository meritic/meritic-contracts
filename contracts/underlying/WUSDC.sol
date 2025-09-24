//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../extensions/Underlying.sol";




contract WUSDC is ERC20("Wrapped USDC", "WUSDC"), Underlying, AccessControl {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
	
	mapping(uint256 => mapping(address => uint256)) private _slotApprovedValues;
	
    /// @notice emitted on mint, minter is address(this)
    event MintWUSDC(address indexed minter, address indexed to, uint256 amount);
    bytes32 public constant TRANSFER_ADMIN_ROLE = keccak256("TRANSFER_ADMIN_ROLE");
    
    constructor(address mktAdminAcct_){
		_grantRole(DEFAULT_ADMIN_ROLE, mktAdminAcct_);

        _grantRole(MINTER_ROLE, mktAdminAcct_);
        _grantRole(BURNER_ROLE, mktAdminAcct_);
        _grantRole(TRANSFER_ADMIN_ROLE, mktAdminAcct_);
    }
    
    
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
    

    
    function burn(address from,  uint256 slotId_, uint256 amount) external {
    	require(hasRole(BURNER_ROLE, msg.sender), "WUSDC: Caller is not a burner");
    	
    	_slotApprovedValues[slotId_][from] -= amount;
    	_burn(from, amount);

	}	
	
    
    
	function mint(address to_, uint256 slotId_, uint256 amount_) external  {
        require(hasRole(MINTER_ROLE, msg.sender), "WUSDC: Caller is not a minter");
    	_mint(to_, amount_);
        _slotApprovedValues[slotId_][msg.sender] += amount_;
        emit MintWUSDC(msg.sender, to_, amount_);
    }

    function _mint(address to, uint256 amount) internal override {
   		super._mint(to, amount); 
    }
    
    

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(hasRole(TRANSFER_ADMIN_ROLE, from), "WUSDC: Transfer refused. Unauthorized account");
        
        return super.transferFrom(from,  to,  amount);
    }
    
    function transfer(address to, uint256 amount) public virtual override (ERC20, Underlying) returns (bool) {
        bool result = super.transfer(to, amount);
        return result;
        
    }

}


