//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
/*
 * import "@openzeppelin/contracts/access/Ownable.sol";
	import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
	import "./WETH.sol";
 * 
 */


import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";




contract WETH is ERC20("Wrapped Ether", "WETH") {
    
    event Deposit(address 	indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);


	function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    
    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
        //msg.sender.transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }
    
    function withdraw(uint256 amount, address user) public {
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
        payable(user).transfer(amount);
        //emit Withdrawal(user, amount);
    }

    receive() external payable virtual {
        deposit();
    }
    
    

	
}

