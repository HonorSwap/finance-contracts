//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IHonorTreasureV1 {
    function depositToken(address token,uint256 amount) external;
    function depositWETH(uint256 amount) external;
    function depositHonor(uint256 amount) external;
    function widthdrawToken(address token) external;
    function widthdrawWETH() external;
    function widthdrawHonor(uint256 amount,address user) external;
    function getTokenReserve(address token) external view returns(uint256);
    function getWETHReserve() external view returns(uint256);
    function getPairAllReserve(address token0,address token1) external view returns(uint112 ,uint112 );
    function getHonorBUSDValue(uint256 amount) external view returns(uint256); 
    function getBUSDHonorValue(uint256 amount) external view returns(uint256); 
}