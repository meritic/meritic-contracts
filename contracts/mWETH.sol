//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
/*
 * import "@openzeppelin/contracts/access/Ownable.sol";
	import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
	import "./WETH.sol";
 * 
 */




import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC20.sol";
import "../utils/SafeTransferLib.sol";



contract mWETH is ERC20("Wrapped Ether", "WETH", 18) {
    
    using SafeTransferLib for address;
    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}










interface IWETH is IERC20 {
  function deposit() external payable;
  function withdraw(uint256 wad) external;
}




contract Swap {
  address private weth;
  
  constructor(address eth_) { weth = eth_; }
  
  function wrapEther() external payable {
    uint256 ETHAmount = msg.value;

    //create WETH from ETH
    if (msg.value != 0) {
      IWETH(weth).deposit{ value: ETHAmount }();
    }
    require(
      IWETH(weth).balanceOf(address(this)) >= ETHAmount,
      "Ethereum not deposited"
    );
    
    // transfer will do, you don't need to use transferFrom, use it only when the tokens you want to transfer arent held by the contract (like in unwrapEther())  
    IWETH(weth).transfer(msg.sender, IWETH(weth).balanceOf(address(this)));
  }
  
  // To receive ETH from the WETH's withdraw function (it won't work without it) 
  receive() external payable {}
  
  
  function unwrapEther(uint256 Amount) external {
    address payable sender = payable(msg.sender);
    if (Amount != 0) {
      // Taking tokens from a wallet require allowance, look up https://eips.ethereum.org/EIPS/eip-20#methods, especially the paragraphs on transferFrom() and approve()
      require(IWETH(weth).allowance(msg.sender, address(this)) >= Amount, "insufficient allowance");
      IWETH(weth).transferFrom(msg.sender, address(this), Amount);
      IWETH(weth).withdraw(Amount);
      sender.transfer(address(this).balance);
    }
  }
}