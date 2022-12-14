
const hre = require("hardhat");

async function main() {

const [owner, otherAccount] = await hre.ethers.getSigners();

  const Factory = await hre.ethers.getContractFactory("contracts/HonorFactory.sol:HonorFactory");
  const factory = await Factory.deploy(owner.address);

  await factory.deployed();

  const codePair=await factory.INIT_CODE_PAIR_HASH();
  console.log(
    `Factory  deployed to ${factory.address} CODE PAIR: ${codePair}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
