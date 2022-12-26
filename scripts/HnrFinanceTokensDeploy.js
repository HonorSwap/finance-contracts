
const hre = require("hardhat");

async function main() {

const [owner, otherAccount] = await hre.ethers.getSigners();


const honor="0x37CA99B38902c90fE8BDB23D5FDcD36D0a46Ef93";
const weth="0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd";
const treasure="0xfB30056203a0F3a7Ee0388E75cBF8f02613e6a27";



  
const HNRT = await hre.ethers.getContractFactory("contracts//HnrFinanceTokens.sol:HnrFinanceTokens");
const hnrT = await HNRT.deploy(honor,weth,treasure);

  await hnrT.deployed();


  console.log(
    `FinanceTokens  deployed to ${hnrT.address} `
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
