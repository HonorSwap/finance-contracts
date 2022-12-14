// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

import "./Helpers/SafeMath.sol";
import "./Helpers/Ownable.sol";
import "./Helpers/TransferHelper.sol";
import "./Helpers/IERC20.sol";

contract HnrFinanceHUSD is Ownable
{
    using SafeMath for uint256;

    address public _busdToken;
    address public _husdToken;
    address public _xhnrToken;
    address public _feeTo;

    uint256 public _FEE=50;

    uint256 _totalBUSD;

    constructor(address busd,address husd,address xhnrToken,address feeTo) public {
        _busdToken=busd;
        _husdToken=husd;
        _xhnrToken=xhnrToken;
        _feeTo=feeTo;
    }

    function setFeeTo(address feeTo) public onlyOwner {
        _feeTo=feeTo;
    }

    function setFee(uint256 _fee) public onlyOwner {
        _FEE=_fee;
    }
    function hUSDBalance() public view returns(uint256) {
        return IERC20(_husdToken).balanceOf(address(this));
    }

    function depositBUSD(uint256 amount) public {
        uint256 husdAmount=IERC20(_husdToken).balanceOf(address(this));

        require(husdAmount>=amount,"Not Amount");
        uint256 fee=amount.mul(_FEE).div(100000);

        TransferHelper.safeTransferFrom(_busdToken, msg.sender, address(this), amount);
        TransferHelper.safeTransfer(_busdToken, _feeTo, fee);

        uint256 curAmount=amount.sub(fee);
        TransferHelper.safeTransfer(_husdToken, msg.sender, curAmount);

        curAmount=amount.mul(1000);
        TransferHelper.safeTransfer(_xhnrToken, msg.sender, curAmount);
        _totalBUSD=_totalBUSD.add(amount);
    }

    /*
    User sent HNRUSD to Contract get BUSD 
    User send xHonor Token to Contract amount x 1500
    */
    function buyBUSD(uint256 amount) public {
        uint256 busdAmount=IERC20(_busdToken).balanceOf(address(this));
        require(busdAmount>=amount,"Not amount");

        uint256 fee=amount.mul(_FEE).div(100000);
        
        uint256 curAmount=amount.mul(1500);

        TransferHelper.safeTransferFrom(_xhnrToken, msg.sender, address(this),curAmount);
        TransferHelper.safeTransferFrom(_husdToken, msg.sender, address(this), amount);
        TransferHelper.safeTransfer(_husdToken, _feeTo, fee);

        curAmount=amount.sub(fee);
        TransferHelper.safeTransfer(_busdToken, msg.sender, curAmount);
    }

    /*
    User sent BUSD to Contract get HNRUSD 
    Contract send xHonor Token to User amount x 1000
    */
    function buyHUSD(uint256 amount) public {
        uint256 husdAmount=IERC20(_husdToken).balanceOf(address(this));
        require(husdAmount>=amount,"Not Amount");


        uint256 fee=amount.mul(_FEE).div(100000);

        TransferHelper.safeTransferFrom(_busdToken, msg.sender, address(this), amount);
        TransferHelper.safeTransfer(_busdToken, _feeTo, fee);

        uint256 curAmount=amount.sub(fee);
        TransferHelper.safeTransfer(_husdToken, msg.sender, curAmount);

        curAmount=amount.mul(1000);
        TransferHelper.safeTransfer(_xhnrToken, msg.sender, curAmount);
    }

}