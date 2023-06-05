//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "./ERC20.sol";
import "../../utils/SafeTransferLib.sol";

import "../extensions/IValue.sol";





contract WUSDC is ERC20("Wrapped USDC", "WUSDC"), IValue {
    
    using SafeTransferLib for address;

    ERC20 private usdc;
    //address temp=0x60Ae865ee4C725cd04353b5AAb364553f56ceF82;
    //address private MumbaiTestUSDC = 0x768b65f3f5CeC686A58444D3Eb8f9156523D53b3;
    address private TestUSDC = 0xeD97f5a6eafC2Ec7412bBe38a67d60B628344512;
    
    /// @notice emitted on mint, minter is address(this)
    event MintWUSDC(address indexed minter, address indexed to, uint256 amount);
    
    constructor(){
        usdc = ERC20(TestUSDC); //IERC20(0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747);
    }
    
    
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
    
    /// @notice emitted on redeem, redeemer is msg.sender
    event Redeem(address indexed redeemer, uint256 amount);





    function mint(uint256 amount, address to) external payable {
        _mint(amount, to);
        emit MintWUSDC(msg.sender, to, amount);
    }
    
    
    function redeem(uint256 amount, address to) external payable{
        _redeem(amount, to);
    }
    
    
    
    
    function _redeem(uint256 amount, address to) private {
        _burn(msg.sender, amount); /// subtract internal balance first

        /// interaction
        usdc.transfer(to, amount); /// pay out USDC

        emit Redeem(msg.sender, amount);
    }
    
    
    
	

    function _mint(uint256 amount, address to) private returns (bool){
        usdc.approve(to, amount);
   		usdc.transfer(to, amount); 
   		super._mint(to, amount); /// mint WUSD
    }
    
    

    
    function transfer(address from_, address to_, uint256 value_) external payable {
       transferFrom(from_, to_, value_);
    }
    
	
    
}


