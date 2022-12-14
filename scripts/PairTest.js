
const { ethers } = require("hardhat");
const hre = require("hardhat");

function parseETH(value) {
  return ethers.utils.parseEther(value);
}
async function main() {
/*
const [owner, otherAccount] = await hre.ethers.getSigners();

const pair="0xDA8ceb724A06819c0A5cDb4304ea0cB27F8304cF";
const _to="0x1b09d1979C576248D04cF532d9E864ADCbd9b409";
const pairContract=await ethers.getContractAt("contracts/Helpers/IHonorPair.sol:IHonorPair",pair);

const res=await pairContract.getReserves();
const data=[];
await pairContract.swap(parseETH("100"),parseETH("0"),_to,data);
console.log(res);
*/
}



main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
