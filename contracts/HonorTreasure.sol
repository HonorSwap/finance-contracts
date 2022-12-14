// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

import "./Helpers/SafeMath.sol";
import "./Helpers/Ownable.sol";
import "./Helpers/TransferHelper.sol";
import "./Helpers/IERC20.sol";
import "./Helpers/ISwapRouter.sol";
import "./Helpers/IHonorFactory.sol";
import "./Helpers/IHonorPair.sol";
import "hardhat/console.sol";


// Olayı çözdüm Routerdaki transferFrom çalışmıyor bence

contract HonorTreasure is Ownable
{
    using SafeMath for uint256;

    address public _busdToken;
    address public _husdToken;
    address public _wbnbToken;
    address public _honorToken;

    IHonorFactory _factory;

    ISwapRouter private _routerHonor;
    ISwapRouter private _router1;
    ISwapRouter private _router2;

    uint256 public constant _MAX= ~uint256(0);
    uint256 private _busdForHUSD=0;

    constructor(address busd,address husd,address honor,address router) public {
        _busdToken=busd;
        _husdToken=husd;
        _honorToken=honor;

        _routerHonor=ISwapRouter(router);
        _wbnbToken=_routerHonor.WETH();
        _factory=IHonorFactory(_routerHonor.factory());

        IERC20(honor).approve(router,_MAX);
        IERC20(busd).approve(router,_MAX);
        IERC20(husd).approve(router,_MAX);
        IERC20(_wbnbToken).approve(router,_MAX);
    }

    function setRouters(address router1,address router2) public onlyOwner {
        _router1=ISwapRouter(router1);
        _router2=ISwapRouter(router2);
  
        IERC20(_honorToken).approve(router1,_MAX);
        IERC20(_busdToken).approve(router1,_MAX);
        IERC20(_husdToken).approve(router1,_MAX);
        IERC20(_wbnbToken).approve(router1,_MAX);

        IERC20(_honorToken).approve(router2,_MAX);
        IERC20(_busdToken).approve(router2,_MAX);
        IERC20(_husdToken).approve(router2,_MAX);
        IERC20(_wbnbToken).approve(router2,_MAX);
    }

    
    function depositBUSD(uint256 amount) public {
        
        TransferHelper.safeTransferFrom(_busdToken, msg.sender, address(this), amount);
        console.log("Transfer OK");

        uint256 buyAmount=amount.mul(2).div(10);
        _swap(_busdToken,_honorToken,buyAmount);

        console.log("BUy OK");
        _routerHonor.addLiquidity(_busdToken, _honorToken, amount, _MAX, 0, 0, address(this), block.timestamp+300);
   }

   function depositBUSDForHUSD(uint256 amount) public {
    TransferHelper.safeTransferFrom(_busdToken, msg.sender, address(this), amount);
    _busdForHUSD=_busdForHUSD.add(amount);
   }


    function removeLiq(address tokenA,address tokenB) private {
        address pair=_factory.getPair(tokenA, tokenB);
        uint256 liquidity=IERC20(pair).balanceOf(address(this));
        if(liquidity>0)
        {
            _routerHonor.removeLiquidity(tokenA, tokenB, liquidity, 0, 0, address(this), block.timestamp);
        }
    }
   function removeAllLiquidityAdmin() public onlyOwner {
    removeLiq(_busdToken, _honorToken);
    removeLiq(_honorToken,_husdToken);
    removeLiq(_wbnbToken,_honorToken);
    removeLiq(_busdToken,_husdToken);
    }

    function _swap(address tokenIn,address tokenOut,uint256 amount) private {
        (address router,uint256 amountOut)=checkAmountMin(tokenIn, tokenOut, amount);

        address[] memory path;
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        
        ISwapRouter(router).swapExactTokensForTokens(amount, amountOut, path, address(this), block.timestamp);
   }

function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'HonorLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'HonorLibrary: ZERO_ADDRESS');
    }

function depositBUSDLast(uint256 amount) public {
        uint256 buyAmount=amount.mul(2).div(10);
        swapInPair(_busdToken, _wbnbToken, buyAmount, msg.sender);
        swapInPair(_busdToken,_honorToken,buyAmount,msg.sender);

    }

    function buyHonorForBUSD() public onlyOwner {
        uint256 amount=IERC20(_busdToken).balanceOf(address(this));
        address[] memory path=new address[](2);
        path[0]=_busdToken;
        path[1]=_honorToken;
        uint deadline=block.timestamp + 300;
        _routerHonor.swapExactTokensForTokens(amount, 1, path, address(this), deadline);
    }
   function swapInPair(address input,address output,uint256 amount,address user) private {
    (address router,uint256 amountOut)=checkAmountMin(input, output, amount);
    IHonorFactory factory=IHonorFactory(ISwapRouter(router).factory());
    IHonorPair pair=IHonorPair(factory.getPair(input, output));

     
    (address token0,) = sortTokens(input, output);
           
    (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));

    TransferHelper.safeTransferFrom(input, user, address(pair), amount);
    
    pair.swap(amount0Out, amount1Out, address(this), new bytes(0));

   }

   function _tradeAdmin(address tokenIn,address tokenOut,uint256 amount) public onlyOwner {
        swapInPair( tokenIn, tokenOut, amount,msg.sender);
   }

   function checkAmountMin(address tokenIn,address tokenOut,uint256 amount) internal view returns(address ,uint256 ) {
        address[] memory path;
		path = new address[](2);
		path[0] = tokenIn;
		path[1] = tokenOut;
		uint256[] memory amountOutMins1 = _router1.getAmountsOut(amount, path);
		uint256 ret1=amountOutMins1[path.length -1];
        uint256[] memory amountOutMins2 = _router2.getAmountsOut(amount, path);
		uint256 ret2=amountOutMins2[path.length -1];
        uint256[] memory amountOutMins3 = _routerHonor.getAmountsOut(amount, path);
		uint256 ret3=amountOutMins3[path.length -1];
        if(ret2>ret1)
        {
            if(ret3>ret2)
                return (address(_routerHonor),ret3);
            
            return (address(_router2),ret2);
        }
        
        return (address(_router1),ret1);
    }
}