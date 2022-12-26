//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Helpers/IHonorTreasureV1.sol";
import "./Helpers/IWETH.sol";

contract HnrFinanceTokens is Ownable {

    using SafeMath for uint256;

    IHonorTreasureV1 public _honorTreasure;
    address public _honorToken;
    address public _wethToken;
    
    uint256 public _awardInterest;

    struct TokenFinance 
    {
        uint256 _maxAmountPerUser;
        uint256 _maxTotalAmount;
        uint256 _totalAmount;
        uint256 _yearInterest;
        uint256 _sixmonthInterest;
        uint256 _threeMonthInterest;
        uint256 _monthInterest;
    }

    struct UserBalance {
        uint start_time;
        uint duration;
        uint interest_rate;
        uint amount;       
    }

    struct HonorBalance {
        uint start_time;
        uint duration;
        uint interest_rate;
        uint256 amount;
        uint256 busdValue;
    }
    mapping(address=>TokenFinance) public _tokenFinances;
    mapping(address=>mapping(address=>UserBalance)) public _userBalances;
    mapping(address=>HonorBalance) _userHonorBalances;

    constructor(address honorToken,address wethToken,address treasure)
    {
        _honorToken=honorToken;
        _wethToken=wethToken;
        _honorTreasure=IHonorTreasureV1(treasure);

        IERC20(_honorToken).approve(treasure, type(uint256).max);
        IERC20(_wethToken).approve(treasure, type(uint256).max);
    }

    function addToken(address token,uint256 maxAmountUser,uint256 maxTotalAmount,
    uint256 year,uint256 six,uint256 three,uint256 month) public onlyOwner {
        TokenFinance storage finance=_tokenFinances[token];
        finance._maxAmountPerUser=maxAmountUser;
        finance._maxTotalAmount=maxTotalAmount;
        finance._yearInterest=year;
        finance._sixmonthInterest=six;
        finance._threeMonthInterest=three;
        finance._monthInterest=month;
        IERC20(token).approve(address(_honorTreasure), type(uint256).max);
    }
    /*
    uint256 public YEAR_INTEREST=5707762557;
    uint256 public SIXMONTH_INTEREST=4883307965;
    uint256 public THREEMONTH_INTEREST=4223744292;
    uint256 public MONTH_INTEREST=3611745307;
    */

    event Deposit(address indexed _from,address indexed _token,uint256 _amount,uint256 duration);
    event Widthdraw(address indexed _from,address indexed _token,uint256 _amount,uint256 duration);


    function setInterestRates(address token,uint256 year,uint256 sixmonth,uint256 threemonth,uint256 month) public onlyOwner {
        TokenFinance storage finance=_tokenFinances[token];
        finance._yearInterest=year;
        finance._sixmonthInterest=sixmonth;
        finance._threeMonthInterest=threemonth;
        finance._monthInterest=month;
    }

    function setAwardInterest(uint256 interest) public onlyOwner {
        _awardInterest=interest;
    }

    function setMaxCaps(address token,uint256 maxPerUser,uint256 maxAmount) public onlyOwner {
        TokenFinance storage finance=_tokenFinances[token];
        finance._maxAmountPerUser=maxPerUser;
        finance._maxTotalAmount=maxAmount;
    }
    function getInterestRate(uint duration,address token) public view returns(uint) {
        TokenFinance memory finance=_tokenFinances[token];

        if(duration>=31536000)
            return finance._yearInterest;
        if(duration>=15552000)
            return finance._sixmonthInterest;
        if(duration>=7776000)
            return finance._threeMonthInterest;
        if(duration>=2592000)
            return finance._monthInterest;
        
        return 0;
    }

    function _depositToken(address user,address token,uint256 amount,uint duration) private {
        TokenFinance storage finance=_tokenFinances[token];
        require(finance._maxAmountPerUser>=amount && finance._maxAmountPerUser>0,"AMOUNT ERROR");

        uint interest=getInterestRate(duration,token);
        require(interest>0,"ERROR DURATION");

        finance._totalAmount += amount;

        require(finance._totalAmount<=finance._maxTotalAmount,"TOTAL AMOUNT ERROR");

        UserBalance storage balance=_userBalances[user][token];

        require(balance.start_time==0,"Current Deposited");

        balance.start_time=block.timestamp;
        balance.interest_rate=interest;
        balance.duration=duration;
        balance.amount=amount;
    }

    function depositHonor(uint256 amount,uint duration) public {
        IERC20(_honorToken).transferFrom(msg.sender,address(this),amount);

        _depositHonor(msg.sender, amount, duration);

        emit Deposit(msg.sender, _honorToken, amount, duration);
    }
    function _depositHonor(address user,uint256 amount,uint duration) private {
        
        TokenFinance storage finance=_tokenFinances[_honorToken];
        require(finance._maxAmountPerUser>=amount && finance._maxAmountPerUser>0,"AMOUNT ERROR");

        uint interest=getInterestRate(duration,_honorToken);
        require(interest>0,"ERROR DURATION");

        finance._totalAmount += amount;

        require(finance._totalAmount<=finance._maxTotalAmount,"TOTAL AMOUNT ERROR");

        HonorBalance storage balance=_userHonorBalances[user];

        require(balance.start_time==0,"Current Deposited");

        balance.start_time=block.timestamp;
        balance.interest_rate=interest;
        balance.duration=duration;
        balance.amount=amount;
        balance.busdValue=_honorTreasure.getHonorBUSDValue(amount);
    }

    
    function depositToken(address token,uint256 amount,uint duration) public {

        IERC20(token).transferFrom(msg.sender,address(this),amount);

        _depositToken(msg.sender,token,amount,duration);

        if(token==_wethToken)
        {
            _honorTreasure.depositWETH(amount);
        }
        else
        {
            _honorTreasure.depositToken(token,amount);
        }
        

        emit Deposit(msg.sender,token,amount,duration);
    }

    function depositWETH(uint256 duration) public payable {
        uint256 amount=msg.value;

        if(amount!=0)
        {
            IWETH(_wethToken).deposit{ value: amount }();
        }

        require(IERC20(_wethToken).balanceOf(address(this))>=amount,"Not Deposit WETH");

        _depositToken(msg.sender,_wethToken,amount,duration);

        _honorTreasure.depositWETH(amount);

        emit Deposit(msg.sender,_wethToken,amount,duration);
    }

    function changeTimeToken(address token,uint256 addAmount,uint duration) public {
        UserBalance storage balance = _userBalances[msg.sender][token];
        require(balance.start_time>0,"NOT START");

        uint elapsedTime=block.timestamp - balance.start_time;

        uint remainTime=balance.duration - elapsedTime;

        require(duration>remainTime,"ERROR TIME");

        balance.start_time=0;

        TokenFinance storage finance=_tokenFinances[token];
        finance._totalAmount -=balance.amount;

        uint256 income=getIncome(balance.amount, elapsedTime, balance.interest_rate);

        uint256 amount=income + balance.amount;
        if(addAmount>0)
        {
            IERC20(token).transferFrom(msg.sender, address(this), addAmount);
            amount=amount.add(addAmount);
            if(token==_wethToken)
            {
                _honorTreasure.depositWETH(addAmount);
            }
            else
            {
                _honorTreasure.depositToken(token,addAmount);
            }
        }
        
        _depositToken(msg.sender, token, amount, duration);

        emit Deposit(msg.sender,token,amount,duration);

    }

    function changeTimeHonor(uint256 addAmount,uint duration) public {
        HonorBalance storage balance = _userHonorBalances[msg.sender];
        require(balance.start_time>0,"NOT START");

        uint elapsedTime=block.timestamp - balance.start_time;

        uint remainTime=balance.duration - elapsedTime;

        require(duration>remainTime,"ERROR TIME");

        balance.start_time=0;

        TokenFinance storage finance=_tokenFinances[_honorToken];
        finance._totalAmount -=balance.amount;

        uint256 income=getIncome(balance.busdValue, elapsedTime, balance.interest_rate);

        uint256 amount=_honorTreasure.getBUSDHonorValue(income + balance.busdValue);
        if(addAmount>0)
        {
            IERC20(_honorToken).transferFrom(msg.sender, address(this), addAmount);
            amount=amount.add(addAmount);

            _honorTreasure.depositHonor(addAmount);
        }
        
        _depositHonor(msg.sender, amount, duration);

        emit Deposit(msg.sender,_honorToken,addAmount,duration);

    }

    function getIncome(uint256 amount,uint256 duration,uint256 rate) public pure returns(uint256) {
        return amount.mul(duration).div(10**18).mul(rate).mul(amount);
    }

    function widthdraw(address token) public {
        UserBalance storage balance=_userBalances[msg.sender][token];
        require(balance.start_time>0,"Not Deposited");
        uint endtime=balance.start_time + balance.duration;
        require(endtime<=block.timestamp,"Not Time");

        uint256 duration=block.timestamp - balance.start_time;

        uint256 income=getIncome(balance.amount,duration,balance.interest_rate);
        uint256 lastBalance=balance.amount.add(income);
        
        if(token==_wethToken)
        {
            if(_honorTreasure.getWETHReserve()>=lastBalance)
            {
                _honorTreasure.widthdrawWETH(lastBalance,msg.sender);
            }
            else
            {
                uint256 count=getAwardHonorCount(_wethToken, lastBalance, income);
                
                _honorTreasure.widthdrawHonor(count,msg.sender);
                //Mint Honor
            }
        }
        else 
        {
            if(_honorTreasure.getTokenReserve(token)>=lastBalance)
            {
                _honorTreasure.widthdrawToken(token,lastBalance,msg.sender);
            }
            else
            {
                uint256 count=getAwardHonorCount(token, lastBalance, income);
                
                _honorTreasure.widthdrawHonor(count,msg.sender);
                //Mint Honor
            }
            
        }
        

        TokenFinance storage finance=_tokenFinances[token];
        finance._totalAmount=finance._totalAmount.sub(balance.amount);
        balance.amount=0;
        balance.duration=0;
        balance.start_time=0;
        balance.interest_rate=0;
        
        emit Widthdraw(msg.sender,token, lastBalance, duration);
        
    }


    function getAwardHonorCount(address token,uint256 amount,uint256 income) public view returns(uint256) {
        uint256 incomeLast=income.mul(_awardInterest).div(100);
        uint256 amountLast=amount.sub(income).add(incomeLast);
        (uint256 tokenRes,uint256 honorRes) = _honorTreasure.getPairAllReserve(token, _honorToken);
        return amountLast.div(tokenRes).mul(honorRes);
    }

    function getUserTokenBalance(address user,address token) public view returns(UserBalance memory) {
        return _userBalances[user][token];
    }
    function getUserHonorBalance(address user) public view returns(HonorBalance memory) {
        return _userHonorBalances[user];
    }
}