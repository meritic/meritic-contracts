
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IERC20.sol';





contract TokenSwap {
    
    address private constant UNISWAP_V2_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45; 	
    // 0xDED33Fff66356AaffBD03a972ef9fd91fe620D3d (Polygon Mumbai)
    
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 
    // 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa (Polygon Mumbai)
    
    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) external {
    
    	//first we need to transfer the amount in tokens from the msg.sender to this contract
    	//this contract will have the amount of in tokens
    	IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        
        //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
    	//by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
    	IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);
    	
    	
    	
        address[] memory path;
        
        if (_tokenIn == WETH || _tokenOut == WETH) {
      		path = new address[](2);
      		path[0] = _tokenIn;
      		path[1] = _tokenOut;
    	} else {
      		path = new address[](3);
      		path[0] = _tokenIn;
      		path[1] = WETH;
      		path[2] = _tokenOut;
    	}
    	
        IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
    }
    
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {

        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }
        
        uint256[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];  
    }  
}
