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
        uint256 totalPrize;
        uint8[6][] tickets;
        uint8[6] winNumbers;
        uint32 win3Count;
        uint32 win4Count;
        uint32 win5Count;
        uint32 win6Count;
        uint8 status;
        uint ticketCount;
        address[] users;
    }

    mapping(uint=>Lottery) public _lotteries;

    uint public currentLotteryID;
    
    mapping(address=>mapping(uint=>uint8[6][])) public _userTickets;
    mapping(address=>mapping(uint=>uint)) public _userLotUserIDs;
    mapping(address=>uint[]) public userLotteries;
    address public _feeTo;
    uint256 _FEE=30;
    
    address public _lotteryTicket;
    address public _hnrusd;

    uint256 _freeBalance;

    uint _MAXNUMBER=51;

    uint256 _prizeTicket=2 * 10**17;
    uint256 _maxUserTicket=100;



    function getTicketPrice(uint count) public view returns(uint256) {
        return count.mul(_priceTicket);
    }

    function buyTickets(uint8[6][] memory tickets,uint lotteryID) public {
        Lottery storage lottery=_lotteries[lotteryID];
        require(lottery.startBlock>=block.number && lottery.endBlock<block.number,"ERROR LOT ID");

        uint256 count=tickets.length;

        require(count<=20 && count>0,"MAX TICKET 20");

        uint userCount=_userTickets[msg.sender][lotteryID].length;
        require((userCount+count)<=_maxUserTicket,"USER MAX TICKET");

        
        uint256 prize=getTicketPrice(lottery.ticketPrize);
        if(count>=5 && count<10)
        {
            prize=prize.mul(9).div(10);
        }
        else if(count>=10 && count<15)
        {
            prize=prize.mul(85).div(100);
        }
        else if(count>15)
        {
            prize=prize.mul(4).div(5);
        }

        IERC20(_hnrusd).transferFrom(msg.sender, address(this), prize);
        
        
        lottery.totalPrize=lottery.totalPrize + prize;
        
        if(userCount==0)
        {
            addUserLottery(msg.sender, lotteryID);
        }

        for(uint i=0;i<count;i++)
        {
            lottery.tickets.push(tickets[i]);
            _userTickets[msg.sender][lotteryID].push(tickets[i]);
        }
    }

    function addUserLottery(address user,uint lotteryID) private returns(uint) {
        Lottery storage lottery=_lotteries[lotteryID];
        userLotteries[user].push(lotteryID);
        uint userID=lottery.users.length;
        lottery.users.push(user);
        _userLotUserIDs[user][lotteryID]=userID;
        return userID;
    }
    function checkUserCount(address user,uint lotID,uint count) private returns(uint) {
        uint userCount=_userTickets[user][lotID].length;
        require((userCount+count)<=_maxUserTicket,"USER MAX TICKET");
        return userCount;
    }
    function playFreeTickets(uint8[6][] memory tickets,uint lotteryID) public {
        Lottery storage lottery=_lotteries[lotteryID];
        require(lottery.startBlock>=block.number && lottery.endBlock<block.number,"ERROR LOT ID");

        uint256 count=tickets.length;
        uint256 price=lottery.ticketPrize.mul(count).mul(1e18);

        ILotteryTicket(_lotteryTicket).burnTicket(price,msg.sender);
        
        uint userCount=checkUserCount(msg.sender, lotteryID, count);
        
        if(userCount==0)
        {
            addUserLottery(msg.sender, lotteryID);
        }
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

    function getLotteryWinNumber(uint lotID,uint next,uint errorNum) public view returns(uint) {
        Lottery memory lottery=_lotteries[lotID];
        uint256 bHash=blockhash(lottery.endBlock+next);
        uint num=uint(keccak256(abi.encodePacked(bHash,lottery.ticketCount,errorNum))) % _MAXNUMBER;
        return num+1;
    }

    function finishLottery(uint lotID,uint8[6] calldata winNumbers) public onlyOwner {
        Lottery storage lottery=_lotteries[lotID];
        uint lastBlock=lottery.endBlock + 6;

        require(block.number>=lastBlock && lottery.endBlock>0,"ERROR LOTTERY TIME");
        lottery.winNumbers=winNumbers;
        lottery.ticketCount=lottery.tickets.length;
        lottery.status=1; //Check Tickets
    }

    function checkUserTickets(uint lotID) public {
        Lottery memory lottery=_lotteries[lotID];
        require(lottery.status==2,"NOT FINISH CHECK");
        uint8[6][] memory tickets=_userTickets[msg.sender][lotID];
        

        uint count=tickets.length;
        require(count>0,"NOT USER TICKET");

        uint8[6] memory wins=lottery.winNumbers;
        uint[7] memory userWins;
        uint win=0;
        for(uint i=0;i<count;i++)
        {
            win=checkTicket(lottery.winNumbers,tickets[i]);
            userWins[win]++;
        }

    }

    function checkTicket(uint8[6] memory winNumber,uint8[6] memory check) public returns(uint) {
        uint win=0;
        for(uint x=0;x<6;x++) {
            for(uint y=0;y<6;y++)
            {
                if(check[x]==winNumber[y])
                {
                    win++;
                    break;
                }
            }
        }
        return win;
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