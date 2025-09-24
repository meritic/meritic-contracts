//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TestUSDC (for OpenZeppelin v4.x)
 * @dev This contract is compatible with older versions of the OpenZeppelin library.
 */
contract TestUSDC is ERC20, Ownable {
    
    /**
     * @dev Sets the token name, symbol, and mints the initial supply.
     */
    // --- THIS IS THE FIX ---
    // The Ownable() modifier is called without any arguments in older versions.
    // It automatically sets the owner to the contract deployer (msg.sender).
    constructor() ERC20("Test USDC", "TUSDC") {
        // Mint an initial supply of 1,000,000 tokens to the wallet that deploys the contract.
        _mint(msg.sender, 1_000_000 * (10**6));
    }

    /**
     * @notice Overrides the default ERC20 decimals function to return 6, matching real USDC.
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
    
    /**
     * @notice Allows the contract owner to mint new tokens to any address.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        // The amount is multiplied by 10**6 to account for the 6 decimals.
        _mint(to, amount * (10**6));
    }
}