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

    struct FinanceContract
    {
        bool active;
        uint256 buyAmount;
        uint256 sellAmount;
        uint256 mintAmount;
    }
    mapping(address=>FinanceContract) public financeContracts;

    function addFinanceContract(address finance) public onlyOwner {
        FinanceContract storage fContracts=financeContracts[finance];
        fContracts.active=true;
    }

    function isActiveFinanceContract(address finance) public view returns(bool) {
        return financeContracts[finance].active;
    }

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

    
    function depositBUSD(uint256 amount) external {
        require(isActiveFinanceContract(msg.sender)==true,"Not Finance");

        uint256 buyAmount=amount.mul(2).div(10);
        _swap(_busdToken,_honorToken,buyAmount);
        _swap(_busdToken,_wbnbToken,buyAmount);

        uint256 wbnbBalance=IERC20(_wbnbToken).balanceOf((address(this)));
        uint256 wAmount=wbnbBalance.div(2);

        uint deadline=block.timestamp+300;

        _routerHonor.addLiquidity(_wbnbToken, _honorToken, wAmount, _MAX, 0, 0,  address(this), deadline);
        (,uint256 amountBUSD,)=_routerHonor.addLiquidity(_wbnbToken, _busdToken, wAmount, _MAX, 0, 0,  address(this), deadline);
        uint256 lastAmount=amount.sub(buyAmount).sub(buyAmount).sub(amountBUSD);

        _routerHonor.addLiquidity(_busdToken, _honorToken, lastAmount, _MAX, 0, 0, address(this), deadline);
   }

   function depositBUSDForHUSD(uint256 amount) public {
    TransferHelper.safeTransferFrom(_busdToken, msg.sender, address(this), amount);
    _busdForHUSD=_busdForHUSD.add(amount);
   }

   function depositHNRUSD(uint256 amount) public {
        require(isActiveFinanceContract(msg.sender)==true,"Not Finance");
        uint256 busdBalance=IERC20(_busdToken).balanceOf(address(this));
        uint256 husdBUSD=busdBalance > _busdForHUSD ? _busdForHUSD : busdBalance;

        uint deadline=block.timestamp + 300;

        if(husdBUSD>0)
        {
            if(husdBUSD>=amount)
            {
                _routerHonor.addLiquidity(_husdToken,_busdToken,amount,_MAX,0,0,address(this),deadline);
            }
            else
            {
                
                (,uint256 value,)=_routerHonor.addLiquidity(_busdToken,_husdToken,husdBUSD,_MAX,0,0,address(this),deadline);
                uint256 left=amount.sub(value);
                _routerHonor.addLiquidity(_husdToken,_honorToken,left,_MAX,0,0,address(this),deadline);
            }
        }
        else
        {
                _routerHonor.addLiquidity(_husdToken,_honorToken,amount,_MAX,0,0,address(this),deadline);
        }
   }

   function depositHonor(uint256 amount) public {
        require(isActiveFinanceContract(msg.sender)==true,"Not Finance");

        uint256 buyAmount=amount.mul(15).div(100);
        _swap(_honorToken,_busdToken,buyAmount);
        _swap(_honorToken,_wbnbToken,buyAmount);

        uint256 wbnbBalance=IERC20(_wbnbToken).balanceOf((address(this)));
        uint256 wAmount=wbnbBalance.div(2);

        uint deadline=block.timestamp+300;

        _routerHonor.addLiquidity(_wbnbToken, _honorToken, wAmount, _MAX, 0, 0,  address(this), deadline);
        (,uint256 amountBUSD,)=_routerHonor.addLiquidity(_wbnbToken, _busdToken, wAmount, _MAX, 0, 0,  address(this), deadline);
        uint256 lastAmount=amount.sub(buyAmount).sub(buyAmount).sub(amountBUSD);

        _routerHonor.addLiquidity(_busdToken, _honorToken, lastAmount, _MAX, 0, 0, address(this), deadline);
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

    function _swap(address tokenIn,address tokenOut,uint256 amount) private returns (uint[] memory amounts){
        (address router,uint256 amountOut)=checkAmountMin(tokenIn, tokenOut, amount);

        address[] memory path;
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        
        uint deadline=block.timestamp + 300;
        return ISwapRouter(router).swapExactTokensForTokens(amount, amountOut, path, address(this), deadline);
   }



    function buyAdmin(uint256 amount) public onlyOwner {
        uint deadline=block.timestamp+300;
        address[] memory path;
        path = new address[](2);
        path[0] = _busdToken;
        path[1] = _honorToken;
        ISwapRouter(_routerHonor).swapExactTokensForTokens(amount, 1, path, address(this), deadline);
        ISwapRouter(_routerHonor).swapExactTokensForTokens(amount, 1, path, address(this), deadline);
        ISwapRouter(_routerHonor).swapExactTokensForTokens(amount, 1, path, address(this), deadline);
    }
   function addLiq(uint256 amount) public onlyOwner {
    uint deadline=block.timestamp+300;
    _routerHonor.addLiquidity(_busdToken, _honorToken, amount, _MAX, 0, 0, address(this), deadline);
   }

   function _tradeAdmin(address tokenIn,address tokenOut,uint256 amount) public onlyOwner {
        _swap(tokenIn,tokenOut,amount);
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