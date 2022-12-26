
const hre = require("hardhat");

async function main() {

const [owner, otherAccount] = await hre.ethers.getSigners();
const busd="0x388672B44fD9370EAae35Ccc7A4a32F10b54da62";

const honor="0x37CA99B38902c90fE8BDB23D5FDcD36D0a46Ef93";

const router="0x2C0648017f0162E4C87C3ff215918783DdCd53c3";
const honorController="0xF6d102c7457A2f25bF6678498aD0007848233634";


  
const HNRT = await hre.ethers.getContractFactory("contracts//HonorTreasureV1.sol:HonorTreasureV1");
const hnrT = await HNRT.deploy(busd,honor,router,honorController);

  await hnrT.deployed();


  console.log(
    `HonorTreasure  deployed to ${hnrT.address} `
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
