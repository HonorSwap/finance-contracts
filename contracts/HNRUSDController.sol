//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Helpers/IHonorTreasureV1.sol";

contract HNRUSDController is Ownable {

    using SafeMath for uint256;

    address public _busdToken;
    address public _hnrusdToken;
    address public _xhnrToken;

    uint256 _totalBUSDReserve;
    uint256 public _FEE=15;

    address public _treasureAddress;

    constructor(address busd,address husd,address xhnr) public {
        _busdToken=busd;
        _hnrusdToken=husd;
        _xhnrToken=xhnr;
    }

    function setTreasure(address treasure) public onlyOwner {
        _treasureAddress=treasure;

        IERC20(_busdToken).approve(_treasureAddress, type(uint256).max);
    }

    function setFee(uint256 fee) public onlyOwner {
        require(fee<=40 && fee>=1,"MAX FEE");

        _FEE=fee;
    }

    function buyHNRUSD(uint256 amount) public {
        require(getHNRUSDReserve()>=amount,"NOT TREASURE");

        IERC20(_busdToken).transferFrom(msg.sender, address(this), amount);
        IERC20(_xhnrToken).transfer(msg.sender, amount.mul(100));
        uint256 fee=amount.mul(_FEE).div(10000);
        IERC20(_hnrusdToken).transfer(msg.sender, amount.sub(fee));
        _totalBUSDReserve=_totalBUSDReserve.add(amount);

        IHonorTreasureV1(_treasureAddress).depositBUSDForHNRUSD(amount);

    }

    function buyBUSD(uint256 amount) public {
        require(_totalBUSDReserve>=amount,"NOT TREASURE");

        IERC20(_hnrusdToken).transferFrom(msg.sender, address(this), amount);
        IERC20(_xhnrToken).transferFrom(msg.sender,address(this), amount.mul(150));
        uint256 fee=amount.mul(_FEE).div(10000);

        uint256 balance=IERC20(_busdToken).balanceOf(address(this));
        
        uint256 toBalance=amount.sub(fee);

        if(balance<toBalance)
        {
            uint256 need=toBalance.sub(balance);
            IHonorTreasureV1(_treasureAddress).widthdrawBUSDforHNRUSD(need);

        }

        IERC20(_busdToken).transfer(msg.sender, toBalance);

        _totalBUSDReserve=_totalBUSDReserve.sub(toBalance);

    }

    function getBUSDReserve() public view returns(uint256) {
        return _totalBUSDReserve;
    }

    function getHNRUSDReserve() public view returns(uint256) {
        return IERC20(_hnrusdToken).balanceOf(address(this));
    }
    function recoverEth() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function recoverTokens(address tokenAddress) external onlyOwner {
    IERC20 token = IERC20(tokenAddress);
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }
}