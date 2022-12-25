
const hre = require("hardhat");

async function main() {

const [owner, otherAccount] = await hre.ethers.getSigners();


  
const LOTTERY = await hre.ethers.getContractFactory("contracts/HonorLotteryHUSD.sol:HonorLotteryHUSD");
const lottery = await LOTTERY.deploy();

  await lottery.deployed();


  console.log(
    `lottery  deployed to ${lottery.address} `
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
