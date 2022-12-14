
const hre = require("hardhat");

async function main() {

const [owner, otherAccount] = await hre.ethers.getSigners();


  
const INSTAARB = await hre.ethers.getContractFactory("contracts/InstaArb.sol:InstaArb");
const instaArb = await INSTAARB.deploy();

  await instaArb.deployed();


  console.log(
    `instaArb  deployed to ${instaArb.address} `
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
