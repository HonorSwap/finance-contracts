//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Helpers/ILotteryTicket.sol";

contract HonorLotteryHUSD is Ownable {
    using SafeMath for uint256;

    struct Lottery {
        uint256 startBlock;
        uint256 endBlock;
        uint256 balanceStart;
        uint256 ticketPrice;
        uint256 totalPrize;
        uint8[6][] tickets;
        uint8[6] winNumbers;
        uint32 win3Count;
        uint32 win4Count;
        uint32 win5Count;
        uint32 win6Count;
        bool checked;
        uint ticketCount;
    }

    mapping(uint=>Lottery) public _lotteries;

    uint public currentLotteryID;
    
    mapping(address=>mapping(uint=>uint8[6][])) public _userTickets;
    mapping(address=>uint[]) public userLotteries;
    address public _feeTo;
    uint256 _FEE=5;
    
    address public _lotteryTicket;
    address public _hnrusd;


    uint[] _checkLottery;

    uint256 _freeBalance;

    uint _MAXNUMBER=51;

    uint256 _priceTicket=2 * 10**17;


    function getTicketPrice(uint count) public view returns(uint256) {
        return count.mul(_priceTicket);
    }

    function buyTickets(uint8[6][] memory tickets,uint lotteryID) public {
        Lottery storage lottery=_lotteries[lotteryID];
        require(lottery.startBlock>=block.number && lottery.endBlock<block.number,"ERROR LOT ID");

        uint256 count=tickets.length;

        require(count<=20 && count>0,"MAX TICKET 20");

        uint256 price=getTicketPrice(lottery.ticketPrice).mul(count);
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
        price -= fee;
        lottery.totalPrize=lottery.totalPrize.add(price);
        
        for(uint i=0;i<count;i++)
        {
            lottery.tickets.push(tickets[i]);
            _userTickets[msg.sender][lotteryID].push(tickets[i]);
        }
    }

    function playFreeTickets(uint8[6][] memory tickets,uint lotteryID) public {
        Lottery storage lottery=_lotteries[lotteryID];
        
        uint256 count=tickets.length;
        uint256 price=lottery.ticketPrice.mul(count).mul(1000000);

        ILotteryTicket(_lotteryTicket).burnTicket(price,msg.sender);

        for(uint i=0;i<count;i++)
        {
            lottery.tickets.push(tickets[i]);
            _userTickets[msg.sender][lotteryID].push(tickets[i]);
        }
    }



    function getWinNumber(uint blockNumber,uint ticketCount,uint errorNum) public view returns(uint) {
        uint num=uint(keccak256(abi.encodePacked(blockNumber,ticketCount,errorNum))) % _MAXNUMBER;
        return num+1;
    }

    function checkWinNumbers(uint blockNumber,uint ticketCount) public view returns(uint8[6] memory wins)
    {

        uint errorNum=0;

        uint winNum=getWinNumber(blockNumber, ticketCount,errorNum);
        wins[0]=uint8(winNum);
        uint checked=1;
        bool error=false;
        for(uint i=1;i<6;i++)
        {
            if(error)
            {
                i-=1;
                errorNum++;
            }

            uint winNum=uint8(getWinNumber(blockNumber, ticketCount,errorNum));
            
           
            for(uint y=0;y<checked;y++)
            {
                if(wins[y]==winNum)
                {
                    error=true;
                    break;
                }
            }
            if(!error)
            {
                wins[i]=uint8(winNum);
                
                blockNumber++;
                errorNum=0;
                checked++;
            }
        }
    }
    function finishLottery(uint lotID) public onlyOwner {
        Lottery storage lottery=_lotteries[lotID];
        uint lastBlock=lottery.endBlock + 6;

        require(block.number>=lastBlock && lottery.endBlock>0,"ERROR LOTTERY TIME");
        lottery.winNumbers=checkWinNumbers(lottery.endBlock,lottery.tickets.length);
        lottery.ticketCount=lottery.tickets.length;
        
    }
    function checkUserTickets(address user,uint lotID) public view returns(uint[7] memory wins) {
        Lottery memory lottery=_lotteries[lotID];
        if(!lottery.checked)
            return wins;
        uint8[6][] memory uTickets=_userTickets[user][lotID];
        uint count=uTickets.length;
        if(count==0)
            return wins;
            
        for(uint i=0;i<count;i++)
        {
            uint winNumber=0;
            uint8[6] memory ticket=uTickets[i];
            for(uint x=0;x<6;x++)
            {
                for(uint y=0;y<6;y++)
                {
                    if(ticket[x]==lottery.winNumbers[y])
                    {
                        winNumber++;
                        break;
                    }
                }
            }
            if(winNumber<3)
                continue;
            
            if(winNumber==3)
            {
                wins[3]++;
                continue;
            }
            else if(winNumber==4)
            {
                wins[4]++;
                continue;
            }
            else if(winNumber==5)
            {
                wins[5]++;
                continue;
            }
            else if(winNumber==6)
            {
                wins[6]++;
            }
        }
    }

    function getLotteryTickets(uint lotID) public view returns(uint8[6][] memory)
    {
        return _lotteries[lotID].tickets;
    }

    function adminBet(uint num,uint lotID) public onlyOwner {
        Lottery storage lottery=_lotteries[lotID];
        
        uint blocknum=block.number - num;

        for(uint i=0;i<num;i++)
        {
            lottery.tickets.push(checkWinNumbers(blocknum+i,100));
        }

    }

    function createLottery(uint start,uint end,uint price) public onlyOwner returns(uint) {
        
        Lottery storage lottery=_lotteries[currentLotteryID];
        lottery.startBlock=start;
        lottery.endBlock=end;
        lottery.ticketPrice=price;
        currentLotteryID++;
        return currentLotteryID;
    }

    function getTickets(uint lotID) public view returns(uint8[6][] memory) {
        return _lotteries[lotID].tickets;
    }
   
}