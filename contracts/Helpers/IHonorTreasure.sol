pragma solidity =0.6.6;

interface IHonorTreasure {
    function depositBUSD(uint256 amount) external;
    function depositHNRUSD(uint256 amount) external;
    function depositWBNB(uint256 amount) external;
    function depositHonor(uint256 amount) external;
    function getBUSDForHNRUSDBalance() external view returns(uint256);
    function widthdrawBUSD(uint256 amount) external returns(bool);
    function widthdrawHNRUSD(uint256 amount) external returns(bool);
    function widthdrawHonor(uint256 amount) external returns(bool);
    function widthdrawWBNB(uint256 amount) external returns(bool);
    function getLPReserves(address token0,address token1) external view returns(uint256 amount0,uint256 amount1);
    
}