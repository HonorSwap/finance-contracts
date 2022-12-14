//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Router {
  function factory() external pure returns (address);
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

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;
}

interface IHonorController {
  function getHonor(uint256 amount) external;
}

contract HonorTreasureV1 is Ownable {
  using SafeMath for uint256;


  address public _busdToken;
  address public _honorToken;
  address public _wethToken;
  address public _honorRouter;
  address public _router1;
  address public _router2;
  IHonorController public _honorController;

  address _busdWETHPair;
  address _busdHONORPair;
  address _wethHONORPair;

  struct FINANCE_CONTRACTS {
    bool isActive;
    uint256 totalWidthdraw;
    uint256 limit;
  }

  struct TreasureCoin 
  {
    address _wethPair;
    address _honorPair;
    uint256 deposited;
    uint256 widthdrawed;
  }

  mapping(address=>TreasureCoin) public _treasureCoins;
  mapping(address => FINANCE_CONTRACTS) public financeContracts;

  constructor(address busd,address honor,address honorRouter,address honorController)  {
    _honorRouter=honorRouter;
    _busdToken=busd;
    _honorToken=honor;

    _wethToken=IUniswapV2Router(_honorRouter).WETH();
    _honorController=IHonorController(honorController);

    IERC20(_busdToken).approve(_honorRouter,type(uint256).max);
    IERC20(_honorToken).approve(_honorRouter,type(uint256).max);
    IERC20(_wethToken).approve(_honorRouter,type(uint256).max);


    IUniswapV2Factory factory=IUniswapV2Factory(IUniswapV2Router(_honorRouter).factory());
    _busdWETHPair=factory.getPair(_busdToken, _wethToken);
    _busdHONORPair=factory.getPair(_busdToken, _honorToken);
    _wethHONORPair=factory.getPair(_honorToken, _wethToken);

  }

  function addTreasureToken(address _token) public onlyOwner {
    TreasureCoin storage tcoin=_treasureCoins[_token];
    IUniswapV2Factory factory=IUniswapV2Factory(IUniswapV2Router(_honorRouter).factory());

    tcoin._honorPair=factory.getPair(_token, _honorToken);
    tcoin._wethPair=factory.getPair(_token,_wethToken);
    IERC20 _ercToken=IERC20(_token);
    _ercToken.approve(_router1,type(uint256).max);
    _ercToken.approve(_router2,type(uint256).max);
    _ercToken.approve(_honorRouter,type(uint256).max);
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

    IERC20(_busdToken).approve(router2,type(uint256).max);
    IERC20(_honorToken).approve(router2,type(uint256).max);
    IERC20(_wethToken).approve(router2,type(uint256).max);

  }
function swap(address router, address _tokenIn, address _tokenOut, uint256 _amount) private {

    address[] memory path;
    path = new address[](2);
    path[0] = _tokenIn;
    path[1] = _tokenOut;
    uint deadline = block.timestamp + 300;
    IUniswapV2Router(router).swapExactTokensForTokens(_amount, 1, path, address(this), deadline);
  }

 function _addLiquidity(address token0,address token1,uint256 amount) public onlyOwner {
    uint deadline=block.timestamp + 300;
    IUniswapV2Router(_honorRouter).addLiquidity(token0, token1, amount, type(uint256).max, 1, 1, address(this), deadline);
  }

  function _removeLiquidity(address token0,address token1,uint256 amount) public onlyOwner {
    uint deadline=block.timestamp + 300;
     IUniswapV2Router(_honorRouter).removeLiquidity(token0, token1, amount, 1, 1, address(this), deadline);
  }

  function depositToken(address _token,uint256 amount) public {
    IERC20(_token).transferFrom(msg.sender,address(this),amount);
    uint256 buyAmount=amount.div(5);
    (address router,) =checkAmountMin(_token, _wethToken, buyAmount);
    swap(router,_token,_wethToken,buyAmount);
    uint256 balance=IERC20(_wethToken).balanceOf(address(this));
    uint256 liqAmount=balance.div(2);
    uint deadline=block.timestamp + 300;
    
    IUniswapV2Router(_honorRouter).addLiquidity(_wethToken, _honorToken, liqAmount, type(uint256).max, 1, 1, address(this), deadline);
        
    liqAmount=IERC20(_wethToken).balanceOf(address(this));
    IUniswapV2Router(_honorRouter).addLiquidity(_wethToken, _token, liqAmount, type(uint256).max, 1, 1, address(this), deadline);

    balance=IERC20(_token).balanceOf(address(this));

    liqAmount=balance.sub(buyAmount);

    IUniswapV2Router(_honorRouter).addLiquidity(_token, _honorToken, liqAmount, type(uint256).max, 1, 1, address(this), deadline);

    balance=IERC20(_token).balanceOf(address(this));

    ( router,)=checkAmountMin(_token, _honorToken, balance);

    swap(router,_token,_honorToken,balance);
    _treasureCoins[_token].deposited+=amount;
  }
  
  function depositWETH(uint256 amount) public {
        
      IERC20(_wethToken).transferFrom(msg.sender,address(this),amount);

        uint256 buyAmount=amount.div(5);


        (address router,) =checkAmountMin(_wethToken,_busdToken,  buyAmount);

        swap(router,_wethToken,_busdToken,buyAmount);

        uint256 balance=IERC20(_busdToken).balanceOf(address(this));

        uint256 liqAmount=balance.div(2);

        uint deadline=block.timestamp + 300;

        IUniswapV2Router(_honorRouter).addLiquidity(_busdToken, _honorToken, liqAmount, type(uint256).max, 1, 1, address(this), deadline);
        
        liqAmount=IERC20(_busdToken).balanceOf(address(this));
        IUniswapV2Router(_honorRouter).addLiquidity(_busdToken, _wethToken, liqAmount, type(uint256).max, 1, 1, address(this), deadline);

        balance=IERC20(_wethToken).balanceOf(address(this));

        liqAmount=balance.sub(buyAmount);

        IUniswapV2Router(_honorRouter).addLiquidity(_wethToken, _honorToken, liqAmount, type(uint256).max, 1, 1, address(this), deadline);

        balance=IERC20(_wethToken).balanceOf(address(this));

        ( router,)=checkAmountMin(_wethToken, _honorToken, balance);

        swap(router,_wethToken,_honorToken,balance);
    }

    function depositHonor(uint256 amount) public {
       IERC20(_honorToken).transferFrom(msg.sender,address(this),amount);

        uint256 buyAmount=amount.div(4);

        (address router,) =checkAmountMin(_honorToken,_wethToken,  buyAmount);

        swap(router,_honorToken,_wethToken,buyAmount);

        (router,) =checkAmountMin(_honorToken,_busdToken,  buyAmount);

        swap(router,_honorToken,_busdToken,buyAmount);

        uint256 balance=IERC20(_busdToken).balanceOf(address(this));

        uint256 liqAmount=balance.div(2);

        uint deadline=block.timestamp + 300;

        IUniswapV2Router(_honorRouter).addLiquidity(_busdToken, _honorToken, liqAmount, type(uint256).max, 1, 1, address(this), deadline);
        
        liqAmount=IERC20(_busdToken).balanceOf(address(this));
        IUniswapV2Router(_honorRouter).addLiquidity(_busdToken, _wethToken, liqAmount, type(uint256).max, 1, 1, address(this), deadline);

        balance=IERC20(_wethToken).balanceOf(address(this));

        IUniswapV2Router(_honorRouter).addLiquidity(_wethToken, _honorToken, balance, type(uint256).max, 1, 1, address(this), deadline);

    }
    function widthdrawWETH(uint256 amount,address _to) public {
      FINANCE_CONTRACTS storage finance=financeContracts[msg.sender];
      require(finance.isActive==true && finance.limit>=amount,"Not Finance");

      uint deadline=block.timestamp+300;
      uint256 liquidity=IUniswapV2Pair(_wethHONORPair).balanceOf(address(this));
      if(liquidity>0)
      {
        IUniswapV2Router(_honorRouter).removeLiquidity(_wethToken, _honorToken, liquidity, 1, 1, address(this), deadline);
      }

      uint256 balance=IERC20(_wethToken).balanceOf(address(this));
      if(balance>=amount)
      {
        IERC20(_wethToken).transfer(_to,amount);
        
        balance=balance.sub(amount);
        if(balance>0)
        {
          IUniswapV2Router(_honorRouter).addLiquidity(_wethToken, _honorToken, balance, type(uint256).max, 1, 1, address(this), deadline);
        }
      }
      else
      {
        liquidity=IUniswapV2Pair(_busdWETHPair).balanceOf(address(this));
        if(liquidity>0)
        {
          IUniswapV2Router(_honorRouter).removeLiquidity(_busdToken, _wethToken, liquidity, 1, 1, address(this), deadline);
        }

        balance=IERC20(_wethToken).balanceOf(address(this));

        require(balance>=amount,"Not Balance");

        IERC20(_wethToken).transfer(_to,amount);

        balance=balance.sub(amount);
        if(balance>0)
        {
          IUniswapV2Router(_honorRouter).addLiquidity(_wethToken, _honorToken, balance, type(uint256).max, 1, 1, address(this), deadline);
        }

        balance=IERC20(_busdToken).balanceOf(address(this));

        if(balance>0)
        {
          IUniswapV2Router(_honorRouter).addLiquidity(_busdToken, _honorToken, balance, type(uint256).max, 1, 1, address(this), deadline);
        }
      }
    }
    function widthdrawToken(address _token,uint256 amount,address _to) public {
      FINANCE_CONTRACTS storage finance=financeContracts[msg.sender];
      require(finance.isActive==true && finance.limit>=amount,"Not Finance");

      TreasureCoin storage tcoin=_treasureCoins[_token];
      require(tcoin._wethPair!=address(0),"NOT TOKEN");

      uint deadline=block.timestamp + 300;

      uint256 liquidity=IUniswapV2Pair(tcoin._honorPair).balanceOf(address(this));
      if(liquidity>0)
      {
        IUniswapV2Router(_honorRouter).removeLiquidity(_token, _honorToken, liquidity, 1, 1, address(this), deadline);
      }


      uint256 balance=IERC20(_token).balanceOf(address(this));
      if(balance>=amount)
      {
        IERC20(_token).transfer(_to,amount);
        
        balance=balance.sub(amount);
        if(balance>0)
        {
          IUniswapV2Router(_honorRouter).addLiquidity(_token, _honorToken, balance, type(uint256).max, 1, 1, address(this), deadline);
        }
      }
      else
      {
        liquidity=IUniswapV2Pair(tcoin._wethPair).balanceOf(address(this));
        if(liquidity>0)
        {
          IUniswapV2Router(_honorRouter).removeLiquidity(_token, _wethToken, liquidity, 1, 1, address(this), deadline);
        }

        balance=IERC20(_token).balanceOf(address(this));

        require(balance>=amount,"Not Balance");

        IERC20(_token).transfer(_to,amount);

        balance=balance.sub(amount);
        if(balance>0)
        {
          IUniswapV2Router(_honorRouter).addLiquidity(_token, _honorToken, balance, type(uint256).max, 1, 1, address(this), deadline);
        }

        balance=IERC20(_wethToken).balanceOf(address(this));

        if(balance>0)
        {
          IUniswapV2Router(_honorRouter).addLiquidity(_wethToken, _honorToken, balance, type(uint256).max, 1, 1, address(this), deadline);
        }
        
      }

      tcoin.widthdrawed += amount;

    }
    

    function getPairReserve(address pair) public view returns(uint256 res0,uint256 res1) {
      (uint112 res_0,uint112 res_1,)=IUniswapV2Pair(pair).getReserves();
      uint256 balance=IUniswapV2Pair(pair).balanceOf(address(this));
      uint256 totalSupply=IUniswapV2Pair(pair).totalSupply();
      res0=uint256(res_0);
      res1=uint256(res_1);

      res0=res0.mul(balance).div(totalSupply);
      res1=res1.mul(balance).div(totalSupply);
    }

    function widthdrawHonor(uint256 amount,address _to) public {
      FINANCE_CONTRACTS storage finance=financeContracts[msg.sender];
      require(finance.isActive==true && finance.limit>=amount,"Not Finance");

      _honorController.getHonor(amount);

      IERC20(_honorToken).transfer(_to,amount);
    }
    
 

    function getWETHReserve() public view returns(uint256) {
      (uint256 res0,uint256 res1)=getPairReserve(_busdWETHPair);

      uint256 wethTotal1=IUniswapV2Pair(_busdWETHPair).token0() == _wethToken ? res0 : res1;

      ( res0, res1 )=getPairReserve(_wethHONORPair);

      uint256 wethTotal2=IUniswapV2Pair(_wethHONORPair).token0() == _wethToken ? res0 : res1;

      return wethTotal1.add(wethTotal2);
    } 



    function getPairTokenReserve(address pair,address token) public view returns(uint256) {
      (uint112 res_0,uint112 res_1,)=IUniswapV2Pair(pair).getReserves();
      uint256 balance=IUniswapV2Pair(pair).balanceOf(address(this));
      uint256 totalSupply=IUniswapV2Pair(pair).totalSupply();

      uint112 _res=IUniswapV2Pair(pair).token0() == token ? res_0 : res_1;

      uint256 res=uint256(_res);
      
      return res.mul(balance).div(totalSupply);

    }

    function getPairAllReserve(address token0,address token1) public view returns(uint112 ,uint112 ) {
      address pair=IUniswapV2Factory(IUniswapV2Router(_honorRouter).factory()).getPair(token0,token1);
      (uint112 res_0,uint112 res_1,)=IUniswapV2Pair(pair).getReserves();

      if(IUniswapV2Pair(pair).token0()==token0)
      {
        return (res_0,res_1);
      }
      else
      {
        return (res_1,res_0);
      }

    }

    function getHonorBUSDValue(uint256 amount) public view returns(uint256) {
      (uint112 res_0,uint112 res_1,)=IUniswapV2Pair(_busdHONORPair).getReserves();
      (uint256 honorRes,uint256 busdRes) = IUniswapV2Pair(_busdHONORPair).token0()==_honorToken ? (uint256(res_0),uint256(res_1)) : (uint256(res_1),uint256(res_0));
      return amount.mul(busdRes).div(honorRes);
    }

    function getBUSDHonorValue(uint256 amount) public view returns(uint256) {
      (uint112 res_0,uint112 res_1,)=IUniswapV2Pair(_busdHONORPair).getReserves();
      (uint256 honorRes,uint256 busdRes) = IUniswapV2Pair(_busdHONORPair).token0()==_honorToken ? (uint256(res_0),uint256(res_1)) : (uint256(res_1),uint256(res_0));
      return amount.mul(honorRes).div(busdRes);
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