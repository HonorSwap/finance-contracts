//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


//This Contract is Not ERC20
contract LotteryTicket is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _userBalances; 

    address public _lottery;
    address public _lotteryFarm;


    uint256 public _totalTickets;




    function totalTickets() public view  returns (uint256) {
        return _totalTickets;
    }

//Decimal = 6
    constructor(address lottery,address lotteryFarm) {

        _lottery=lottery;
        _lotteryFarm=lotteryFarm;

    }
  
    function userBalance(address account) public view  returns (uint256) {
        return _userBalances[account];
    }

    
    function burnTicket(uint256 amount,address account) public {
        require(msg.sender==_lottery,"NOT LOTTERY");
        require(_userBalances[account]>=amount,"NOT AMOUNT");

        _userBalances[account]-=amount;
        _totalTickets-=amount;
    }

    function mintTicket(uint256 amount,address account) public {
        require(msg.sender==_lotteryFarm,"NOT FARM");

        _userBalances[account] += amount;
        _totalTickets += amount;
    }
}