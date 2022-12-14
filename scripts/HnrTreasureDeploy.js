
const hre = require("hardhat");

async function main() {

const [owner, otherAccount] = await hre.ethers.getSigners();
const busd="0x388672B44fD9370EAae35Ccc7A4a32F10b54da62";
const hnrusd="0xd62f3a589cF119eB4f246b4894a48dE640Fb3a2e";
const honor="0x37CA99B38902c90fE8BDB23D5FDcD36D0a46Ef93";

const router="0x2C0648017f0162E4C87C3ff215918783DdCd53c3";



  
const HNRT = await hre.ethers.getContractFactory("contracts//HonorTreasure.sol:HonorTreasure");
const hnrT = await HNRT.deploy(busd,hnrusd,honor,router);

  await hnrT.deployed();


  console.log(
    `HonorTreasure  deployed to ${hnrT.address} `
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
