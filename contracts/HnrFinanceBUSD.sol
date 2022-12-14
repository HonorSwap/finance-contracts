pragma solidity =0.6.6;

import "./Helpers/SafeMath.sol";
import "./Helpers/Ownable.sol";
import "./Helpers/TransferHelper.sol";
import "./Helpers/IERC20.sol";
import "./Helpers/IHonorTreasure.sol";

contract HnrFinanceBUSD is Ownable {

    using SafeMath for uint256;

    IHonorTreasure public _honorTreasure;
    address public _busdToken;
    address public _honorToken;
    
    uint256 public _maxAmountPerUser=25000 * 10**18;
    uint256 public _maxTotalAmount=100 * 10**6 * 10**18;
    uint256 public _totalAmount;
    uint256 public constant _MAX= ~uint256(0);
    
    uint256 public YEAR_INTEREST=5707762557;
    uint256 public SIXMONTH_INTEREST=4883307965;
    uint256 public THREEMONTH_INTEREST=4223744292;
    uint256 public MONTH_INTEREST=3611745307;

    uint256 public _awardInterest=1010;

    event Deposit(address indexed _from,uint256 _amount,uint256 duration);
    event Widthdraw(address indexed _from,uint256 _amount,uint256 duration);

    struct UserBalance {
        uint start_time;
        uint duration;
        uint interest_rate;
        uint amount;

    }

    mapping(address => UserBalance) public _userBalances;

    constructor(address busd,address honor,address honortreasure) public {
        _busdToken=busd;
        _honorToken=honor;
        _honorTreasure=IHonorTreasure(honortreasure);
        IERC20(_busdToken).approve(honorTreasure,_MAX);
    }

    function setInterestRates(uint256 year,uint256 sixmonth,uint256 threemonth,uint256 month) public onlyOwner {
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
        require(balance<=_maxAmountPerUser,"Max Deposit Error");

        uint interest_rate=getInterestRate(duration);
        require(interest_rate>0,"Not Time");

        _totalAmount=_totalAmount.add(amount);
        require(_totalAmount<=_maxTotalAmount,"Max Total Deposit");
        

        TransferHelper.safeTransferFrom(_busdToken, msg.sender, address(_honorTreasure), amount);

        _honorTreasure.depositBUSD(amount);

        balance.amount=amount;
        balance.duration=duration;
        balance.interest_rate=interest_rate;
        balance.start_time=block.timestamp;

        _totalAmount=_totalAmount.add(amount);

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
        if(!_honorTreasure.widthdrawBUSD(lastBalance))
        {
            _awardHonor(lastBalance);
        }

        _totalAmount=_totalAmount.sub(balance.amount);
        balance.amount=0;
        balance.duration=0;
        balance.start_time=0;
        balance.interest_rate=0;
        
        emit Widthdraw(msg.sender, lastBalance, duration);
        
    }

    function _awardHonor(uint256 busdAmount) private {
        uint256 lastAmount=busdAmount.mul(_awardInterest).div(1000);
        (uint256 busdRes,uint256 honorRes) = _honorTreasure.getLPReserves(_busdToken, _honorToken);
        uint256 honorCount=lastAmount.div(busdRes).mul(honorRes);

        //mint honor
    }
    function getIncome(uint256 amount,uint256 duration,uint256 rate) public pure returns(uint256) {
        return amount.mul(duration).div(10**18).mul(rate).mul(amount);
    }

     
}