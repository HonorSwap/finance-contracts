//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
  function WETH() external pure returns (address);
  function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;
}

contract HonorTreasureV1 is Ownable {
    using SafeMath for uint256;
  address [] public routers;
  address [] public tokens;
  address [] public stables;

  address public _honorRouter;
  address public _busdToken;
  address public _honorToken;
  address public _wethToken;
  address public _hnrusdToken;
  address public _router1;
  address public _router2;

  address public _hnrUSDController;

  constructor(address busd,address hnrusd,address honor,address honorRouter) public {
    _honorRouter=honorRouter;
    _busdToken=busd;
    _honorToken=honor;
    _hnrusdToken=hnrusd;
    _wethToken=IUniswapV2Router(_honorRouter).WETH();

    IERC20(_busdToken).approve(_honorRouter,type(uint256).max);
    IERC20(_honorToken).approve(_honorRouter,type(uint256).max);
    IERC20(_wethToken).approve(_honorRouter,type(uint256).max);
    IERC20(_hnrusdToken).approve(_honorRouter,type(uint256).max);
  }

  function setHNRUSDController(address _controller) public onlyOwner {
    _hnrUSDController=_controller;
  }


  function checkAmountMin(address _tokenIn, address _tokenOut, uint256 _amount) public view returns(address,uint256) {
    uint256 ret0=getAmountOutMin(_honorRouter, _tokenIn, _tokenOut, _amount);
    uint256 ret1=getAmountOutMin(_router1, _tokenIn, _tokenOut, _amount);
    uint256 ret2=getAmountOutMin(_router2, _tokenIn, _tokenOut, _amount);
    if(ret0>=ret1)
    {
        if(ret0>=ret2)
            return (_honorRouter,ret0);
        else
            return (_router2,ret2);
    }
    else
    {
        if(ret1>=ret2)
            return (_router1,ret1);
        else
            return (_router2,ret2);
    }
  }
  
  function setRouters(address router1,address router2) public onlyOwner {
    _router1=router1;
    _router2=router2;

    IERC20(_busdToken).approve(router1,type(uint256).max);
    IERC20(_honorToken).approve(router1,type(uint256).max);
    IERC20(_wethToken).approve(router1,type(uint256).max);
    IERC20(_hnrusdToken).approve(router1,type(uint256).max);
    IERC20(_busdToken).approve(router2,type(uint256).max);
    IERC20(_honorToken).approve(router2,type(uint256).max);
    IERC20(_wethToken).approve(router2,type(uint256).max);
    IERC20(_hnrusdToken).approve(router2,type(uint256).max);
  }



  function depositBUSD(uint256 amount) public {
        IERC20(_busdToken).transferFrom(msg.sender,address(this),amount);

        uint256 buyAmount=amount.div(5);

        (address router,)=checkAmountMin(_busdToken, _honorToken, buyAmount);

        swap(router,_busdToken,_honorToken,buyAmount);

        (router,) =checkAmountMin(_busdToken, _wethToken, buyAmount);

        swap(router,_busdToken,_wethToken,buyAmount);

        uint256 balance=IERC20(_wethToken).balanceOf(address(this));

        uint256 liqAmount=balance.div(2);

        uint deadline=block.timestamp + 300;

        IUniswapV2Router(_honorRouter).addLiquidity(_wethToken, _honorToken, liqAmount, type(uint256).max, 1, 1, address(this), deadline);

        liqAmount=IERC20(_wethToken).balanceOf(address(this));
        IUniswapV2Router(_honorRouter).addLiquidity(_wethToken, _busdToken, liqAmount, type(uint256).max, 1, 1, address(this), deadline);

        balance=IERC20(_busdToken).balanceOf(address(this));
        IUniswapV2Router(_honorRouter).addLiquidity(_busdToken, _honorToken, balance, type(uint256).max, 1, 1, address(this), deadline);

    }

    function depositHNRUSD(uint256 amount) public {
        IERC20(_hnrusdToken).transferFrom(msg.sender,address(this),amount);

        uint256 balanceBUSD=IERC20(_busdToken).balanceOf(_hnrUSDController);

        uint deadline=block.timestamp + 300;
        if(amount<=balanceBUSD)
        {
          IERC20(_busdToken).transferFrom(_hnrUSDController, address(this), amount);
          IUniswapV2Router(_honorRouter).addLiquidity(_hnrusdToken, _busdToken, amount, type(uint256).max, 1, 1, address(this), deadline);
        }
        else
        {
          if(balanceBUSD>0)
          {
            IERC20(_busdToken).transferFrom(_hnrUSDController, address(this), balanceBUSD);
            IUniswapV2Router(_honorRouter).addLiquidity(_busdToken, _hnrusdToken, balanceBUSD, type(uint256).max, 1, 1, address(this), deadline);
          }

          balanceBUSD=IERC20(_hnrusdToken).balanceOf(address(this));

          IUniswapV2Router(_honorRouter).addLiquidity(_hnrusdToken, _honorToken, balanceBUSD, type(uint256).max, 1, 1, address(this), deadline);

        }
    }

    function depositWETH(uint256 amount) public {
        
        IERC20(_wethToken).transferFrom(msg.sender,address(this),amount);

        uint256 buyAmount=amount.div(10);

        (address router,)=checkAmountMin(_wethToken, _honorToken, buyAmount);

        swap(router,_wethToken,_honorToken,buyAmount);

        (router,) =checkAmountMin(_wethToken, _busdToken, buyAmount);

        swap(router,_busdToken,_wethToken,buyAmount);

        uint256 balance=IERC20(_wethToken).balanceOf(address(this));

        uint256 liqAmount=balance.div(2);

        uint deadline=block.timestamp + 300;

        IUniswapV2Router(_honorRouter).addLiquidity(_wethToken, _honorToken, liqAmount, type(uint256).max, 1, 1, address(this), deadline);

        liqAmount=IERC20(_wethToken).balanceOf(address(this));
        IUniswapV2Router(_honorRouter).addLiquidity(_wethToken, _busdToken, liqAmount, type(uint256).max, 1, 1, address(this), deadline);

        balance=IERC20(_busdToken).balanceOf(address(this));
        IUniswapV2Router(_honorRouter).addLiquidity(_busdToken, _honorToken, balance, type(uint256).max, 1, 1, address(this), deadline);

    }

     
  function addLiquidity(address token0,address token1,uint256 amount) private {
    uint deadline=block.timestamp + 300;
    IUniswapV2Router(_honorRouter).addLiquidity(token0, token1, amount, type(uint256).max, 1, 1, address(this), deadline);
  }

  function swap(address router, address _tokenIn, address _tokenOut, uint256 _amount) private {

    address[] memory path;
    path = new address[](2);
    path[0] = _tokenIn;
    path[1] = _tokenOut;
    uint deadline = block.timestamp + 300;
    IUniswapV2Router(router).swapExactTokensForTokens(_amount, 1, path, address(this), deadline);
  }

   function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256 ) {
    address[] memory path;
    path = new address[](2);
    path[0] = _tokenIn;
    path[1] = _tokenOut;
    uint256 result = 0;
    try IUniswapV2Router(router).getAmountsOut(_amount, path) returns (uint256[] memory amountOutMins) {
      result = amountOutMins[path.length -1];
    } catch {
    }
    return result;
  }

  function getBalance (address _tokenContractAddress) external view  returns (uint256) {
    uint balance = IERC20(_tokenContractAddress).balanceOf(address(this));
    return balance;
  }
  
  function recoverEth() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function recoverTokens(address tokenAddress) external onlyOwner {
    IERC20 token = IERC20(tokenAddress);
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

}