
const hre = require("hardhat");

async function main() {

const [owner, otherAccount] = await hre.ethers.getSigners();
const busd="0x388672B44fD9370EAae35Ccc7A4a32F10b54da62";
const honor="0x37CA99B38902c90fE8BDB23D5FDcD36D0a46Ef93";
const hnrTreasure="0xb15c00b9329b1aE135686A189F616b58e6f64BB1";




  
const HNRT = await hre.ethers.getContractFactory("contracts/HnrFinanceBUSD.sol:HnrFinanceBUSD");
const hnrT = await HNRT.deploy(busd,honor,hnrTreasure);

  await hnrT.deployed();


  console.log(
    `HNRBUSDFinance  deployed to ${hnrT.address} `
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
