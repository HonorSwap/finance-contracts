
const hre = require("hardhat");

async function main() {

const [owner, otherAccount] = await hre.ethers.getSigners();

const busd="0x388672B44fD9370EAae35Ccc7A4a32F10b54da62";
const husd="0xd62f3a589cF119eB4f246b4894a48dE640Fb3a2e";
const xhonor="0x0C9364DC0af8596e71229618738310B74E733f76";
const feeTo="0x1b09d1979C576248D04cF532d9E864ADCbd9b409";
  
const FinanceHNRUSD = await hre.ethers.getContractFactory("contracts/Finance/FinanceHnrUsd.sol:FinanceHnrUsd");
const financeHNRUSD = await FinanceHNRUSD.deploy(busd,husd,xhonor,feeTo);

  await financeHNRUSD.deployed();


  console.log(
    `FinanceHNRUSD  deployed to ${financeHNRUSD.address} `
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
