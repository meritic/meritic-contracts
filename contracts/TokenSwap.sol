
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

contract TokenSwap {
    // For the scope of these swap examples,
    // we will detail the design considerations when using
    // `exactInput`, `exactInputSingle`, `exactOutput`, and  `exactOutputSingle`.

    // It should be noted that for the sake of these examples, we purposefully pass in the swap router instead of inherit the swap router for simplicity.
    // More advanced example contracts will detail how to inherit the swap router safely.

    ISwapRouter public immutable swapRouter;

    // This example swaps DAI/WETH9 for single path swaps and DAI/USDC/WETH9 for multi path swaps.

    //address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    //address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    //address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    
    address private constant WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889; 
    address private constant USDC = 0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747;

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    constructor(address _swapRouter) {
        swapRouter = ISwapRouter(_swapRouter);
    }

    /// @notice swapExactInputSingle swaps a fixed amount of WMATIC for a maximum possible amount of USDC
    /// using the WMATIC/USDC 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its WMATIC for this function to succeed.
    /// @param amountIn The exact amount of WMATIC that will be swapped for WETH9.
    /// @return amountOut The amount of USDC received.
    function swapExactInputSingle(uint256 amountIn) external returns (uint256) {
        // msg.sender must approve this contract

        // Transfer the specified amount of WMATIC to this contract.
        TransferHelper.safeTransferFrom(WMATIC, msg.sender, address(this), amountIn);

        // Approve the router to spend WMATIC.
        TransferHelper.safeApprove(USDC, address(swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
												                tokenIn: WMATIC,
												                tokenOut: USDC,
												                fee: poolFee,
												                recipient: msg.sender,
												                deadline: block.timestamp,
												                amountIn: amountIn,
												                amountOutMinimum: 0,
												                sqrtPriceLimitX96: 0
												            });

        // The call to `exactInputSingle` executes the swap.
       	uint256 amountOut = swapRouter.exactInputSingle(params); 
        return amountOut;
        
    }

    /// @notice swapExactOutputSingle swaps a minimum possible amount of WMATIC for a fixed amount of USDC.
    /// @dev The calling address must approve this contract to spend its WMATIC for this function to succeed. As the amount of input WMATIC is variable,
    /// the calling address will need to approve for a slightly higher amount, anticipating some variance.
    /// @param amountOut The exact amount of USDC to receive from the swap.
    /// @param amountInMaximum The amount of WMATIC we are willing to spend to receive the specified amount of USDC.
    /// @return amountIn The amount of WMATIC actually spent in the swap.
    function swapExactOutputSingle(uint256 amountOut, uint256 amountInMaximum) external returns (uint256 amountIn) {
        // Transfer the specified amount of WMATIC to this contract.
        TransferHelper.safeTransferFrom(WMATIC, msg.sender, address(this), amountInMaximum);

        // Approve the router to spend the specifed `amountInMaximum` of WMATIC.
        // In production, you should choose the maximum amount to spend based on oracles or other data sources to acheive a better swap.
        TransferHelper.safeApprove(WMATIC, address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: WMATIC,
                tokenOut: USDC,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = swapRouter.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(WMATIC, address(swapRouter), 0);
            TransferHelper.safeTransfer(WMATIC, msg.sender, amountInMaximum - amountIn);
        }
    }
}




/*contract TokenSwap {
    
    address private constant UNISWAP_V2_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45; 	
    // 0xDED33Fff66356AaffBD03a972ef9fd91fe620D3d (Polygon Mumbai)
    
    address private constant WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889; 
    address private constant USDC = 0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747;
    // 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa (Polygon Mumbai)
    
    

    
    
    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) external {
    
    	address _tokenOut = 0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747;
    	//first we need to transfer the amount in tokens from the msg.sender to this contract
    	//this contract will have the amount of in tokens
    	IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        
        //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
    	//by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
    	IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);
    	
    	
    	
        address[] memory path;
        
        if (_tokenIn == WMATIC || _tokenOut == WMATIC) {
      		path = new address[](2);
      		path[0] = _tokenIn;
      		path[1] = _tokenOut;
    	} else {
      		path = new address[](3);
      		path[0] = _tokenIn;
      		path[1] = WMATIC;
      		path[2] = _tokenOut;
    	}
    	
        IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
    }
    
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {
		address _tokenOut = 0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747;
        address[] memory path;
        if (_tokenIn == WMATIC || _tokenOut == WMATIC) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WMATIC;
            path[2] = _tokenOut;
        }
        //IUniswapV2Router02(UNISWAP_V2_ROUTER);
        uint256[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];  
    }  
}*/
