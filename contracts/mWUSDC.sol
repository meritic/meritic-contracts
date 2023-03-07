//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC20.sol";
import "../utils/SafeTransferLib.sol";






contract mWUSDC is ERC20("Wrapped USDC", "WUSDC", 18) {
    
    using SafeTransferLib for address;
    
    IERC20 public  usdc;
    
	/// @notice emitted on mint, minter is msg.sender
    event Mint(address indexed minter, uint256 amount);
    
    /// @notice emitted on redeem, redeemer is msg.sender
    event Redeem(address indexed redeemer, uint256 amount);

    /// @notice return decimals for WUSDC
    function decimals() public pure override returns (uint8) {
        return 6;
    }
    
    
    function mint(uint256 amount, address to) external {
        _mint(amount, to);
    }
    
    
    function redeem(uint256 amount, address to) external {
        _redeem(amount, to);
    }
    
    
    
    
    function _redeem(uint256 amount, address to) private {
        /// check and effects
        _burn(msg.sender, amount); /// subtract internal balance first

        /// interaction
        USDC.safeTransfer(to, amount); /// pay out USDC

        emit Redeem(msg.sender, amount);
    }


    function _mint(uint256 amount, address to) private {
        /// check and effects
        USDC.safeTransferFrom(msg.sender, address(this), amount); /// sender always pays
        _mint(to, amount); /// mint WUSDC

        emit Mint(msg.sender, amount);
    }
    
}


