//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Helpers/IHonorTreasureV1.sol";

contract HnrFinanceBUSD is Ownable {

    using SafeMath for uint256;

    IHonorTreasureV1 public _honorTreasure;
    address public _busdToken;
    address public _honorToken;
    
    uint256 public _maxAmountPerUser=100000 * 10**18;
    uint256 public _maxTotalAmount=10 * 10**9 * 10**18;
    uint256 public _totalAmount;
    uint256 public constant _MAX= ~uint256(0);
    
    uint256 public YEAR_INTEREST=5707762557;
    uint256 public SIXMONTH_INTEREST=4883307965;
    uint256 public THREEMONTH_INTEREST=4223744292;
    uint256 public MONTH_INTEREST=3611745307;

    event Deposit(address indexed _from,uint256 _amount,uint256 duration);
    event Widthdraw(address indexed _from,uint256 _amount,uint256 duration);

    struct UserBalance {
        uint start_time;
        uint duration;
        uint interest_rate;
        uint amount;
        uint112 resBUSD;
        uint112 resHonor;
    }

    mapping(address => UserBalance) public _userBalances;

    constructor(address busd,address honor,address honorTreasure) public {
        _busdToken=busd;
        _honorToken=honor;
        _honorTreasure=IHonorTreasureV1(honorTreasure);
        IERC20(_honorToken).approve(honorTreasure,_MAX);
    }

    function setInterestRates(uint256 year,uint256 sixmonth,uint256 threemonth,uint256 month) public onlyOwner {
        YEAR_INTEREST=year;
        SIXMONTH_INTEREST=sixmonth;
        THREEMONTH_INTEREST=threemonth;
        MONTH_INTEREST=month;
    }

    function getInterestRate(uint duration) public view returns(uint) {
        if(duration>=31536000)
            return YEAR_INTEREST;
        if(duration>=15552000)
            return SIXMONTH_INTEREST;
        if(duration>=7776000)
            return THREEMONTH_INTEREST;
        if(duration>=2592000)
            return MONTH_INTEREST;
        
        return 0;
    }

    function deposit(uint256 amount,uint duration) public {
        UserBalance storage balance=_userBalances[msg.sender];
        require(balance.start_time==0,"Current Deposited");
        require(amount<=_maxAmountPerUser,"Max Deposit Error");

        uint interest_rate=getInterestRate(duration);
        require(interest_rate>0,"Not Time");

        _totalAmount=_totalAmount.add(amount);
        require(_totalAmount<=_maxTotalAmount,"Max Total Deposit");
        
        _honorTreasure.depositBUSD(amount);//depositHonor

        balance.amount=amount;
        balance.duration=duration;
        balance.interest_rate=interest_rate;
        balance.start_time=block.timestamp;
        (balance.resBUSD,balance.resHonor)=_honorTreasure.getPairAllReserve(_busdToken, _honorToken);

        emit Deposit(msg.sender,amount,duration);
    }

    function widthdraw() public {
        UserBalance storage balance=_userBalances[msg.sender];
        require(balance.start_time>0,"Not Deposited");
        uint endtime=balance.start_time + balance.duration;
        require(endtime<=block.timestamp,"Not Time");

        uint256 duration=block.timestamp - balance.start_time;

        uint256 income=getIncome(balance.amount,duration,balance.interest_rate);
        uint256 lastBalance=balance.amount.add(income);
        
    
        _totalAmount=_totalAmount.sub(balance.amount);

        uint256 resBUSD=uint256(balance.resBUSD);
        uint256 resHonor=uint256(balance.resHonor);

        uint256 busdLast=lastBalance.div(resBUSD).mul(resHonor);

        (uint112 resB,uint112 resH)=_honorTreasure.getPairAllReserve(_busdToken, _honorToken);
        
        balance.amount=0;
        balance.duration=0;
        balance.start_time=0;
        balance.interest_rate=0;
        balance.resBUSD=0;
        balance.resHonor=0;
        
        emit Widthdraw(msg.sender, lastBalance, duration);
        
    }



    function getIncome(uint256 amount,uint256 duration,uint256 rate) public pure returns(uint256) {
        return amount.mul(duration).div(10**18).mul(rate).mul(amount);
    }

     
}