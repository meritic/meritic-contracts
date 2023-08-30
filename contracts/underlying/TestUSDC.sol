//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";




contract TestUSDC is ERC20("Test USDC", "TUSDC") {
    
    function mint(address account, uint256 amount) public  {
        _mint(account, amount);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
