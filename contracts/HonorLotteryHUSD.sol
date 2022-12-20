//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HonorLotteryHUSD is Ownable {
    using SafeMath for uint256;

    struct Lottery {
        uint256 startBlock;
        uint256 endBlock;
        uint256 balanceStart;
        uint256 ticketPrice;
        uint256 totalPrize;
        uint48[] _tickets;
        uint48 winNumber;
    }

    struct UserTickets
    {
        uint lotteryID;
        uint48[] _tickets;
    }

    mapping(uint=>Lottery) public _lotteries;

    uint public currentLotteryID;
    
    mapping(address=>mapping(uint=>uint48[])) public _userTickets;

    address public _feeTo;
    uint256 _FEE=5;
    address public _hnrusd;

    function buyTickets(uint48[] memory tickets,uint lotteryID) public {
        Lottery storage lottery=_lotteries[lotteryID];
        require(lottery.startBlock>=block.number && lottery.endBlock<block.number,"ERROR LOT ID");

        uint256 count=tickets.length;

        require(count<=20,"MAX TICKET 20");

        uint256 price=lottery.ticketPrice.mul(count);
        if(count>=5 && count<10)
        {
            price=price.mul(9).div(10);
        }
        else if(count>=10 && count<15)
        {
            price=price.mul(85).div(100);
        }
        else if(count>15)
        {
            price=price.mul(4).div(5);
        }
        uint256 fee=price.mul(_FEE).div(1000);

        IERC20(_hnrusd).transferFrom(msg.sender, address(this), price);
        IERC20(_hnrusd).transfer(_feeTo, fee);
        price=price.sub(_fee);
        lottery.totalPrize=lottery.totalPrize.add(price);
        
    }
   
}