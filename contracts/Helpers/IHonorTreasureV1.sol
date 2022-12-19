//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IHonorTreasureV1 {
    function depositBUSD(uint256 amount) external;
    function depositHNRUSD(uint256 amount) external;
    function depositBUSDForHNRUSD(uint256 amount) external;
    function widthdrawBUSDforHNRUSD(uint256 amount) external;
}