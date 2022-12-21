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
        uint32 win3Count;
        uint32 win4Count;
        uint32 win5Count;
        uint32 win6Count;
        uint checkedID;
        bool checked;
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

    uint[] _checkLottery;

    uint256 _freeBalance;

    function checkWinNumber(uint256 num) public pure returns(uint48)
    {
        return uint48(num);
    }
    function buyTickets(uint48[] memory tickets,uint lotteryID) public {
        Lottery storage lottery=_lotteries[lotteryID];
        require(lottery.startBlock>=block.number && lottery.endBlock<block.number,"ERROR LOT ID");

        uint256 count=tickets.length;

        require(count<=20 && count>0,"MAX TICKET 20");

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
        price=price.sub(fee);
        lottery.totalPrize=lottery.totalPrize.add(price);
        
        for(uint i=0;i<count;i++)
        {
            lottery._tickets.push(tickets[i]);
            _userTickets[msg.sender][lotteryID].push(tickets[i]);
        }
    }

    function finishLottery(uint lotID,uint48 winNumber) public onlyOwner {
        Lottery storage lot=_lotteries[lotID];
        lot.winNumber=winNumber;
        if(lot._tickets.length>0)
        {
            uint256 balance=lot.balanceStart + lot.totalPrize;
            if(balance>0)
            {
                lot.balanceStart=0;
                lot.totalPrize=balance.sub(balance.div(5));
                _freeBalance=_freeBalance.add(balance.div(5));
            }
            _checkLottery.push(lotID);
        }
    }

    function checkLottery() public {
        if(_checkLottery.length>0)
        {
            Lottery storage lot=_lotteries[_checkLottery[0]];
            uint count=lot._tickets.length;
            
            for(uint i=0;i<20;i++)
            {
                if(lot.checked)
                {
                    break;
                }
                    
                uint48 ticket=lot._tickets[lot.checkedID];
                lot.checkedID+=1;
                
                if(lot.checkedID==count)
                {
                    lot.checked=true;
                }

                if(ticket==lot.winNumber)
                {
                    lot.win6Count++;
                    continue;
                }
                
                /*
                    Check Ticket This Area
                    
                */
                
            }
        }
    }

    function checkTicket(uint48 ticket,uint48 win) public returns(uint) {

    }
   
}