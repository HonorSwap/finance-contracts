//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILotteryTicket {
    function burnTicket(uint256 amount,address account) external; 
    function mintTicket(uint256 amount,address account) external;
    function userBalance(address account) external view returns (uint256);
    function totalTickets() external view returns (uint256);
}