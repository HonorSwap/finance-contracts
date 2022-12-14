
const hre = require("hardhat");

async function main() {

const [owner, otherAccount] = await hre.ethers.getSigners();

const masterChef="0x8348D41f1f918128CCA2712994aA62f48d733F4f";
const honor="0x37CA99B38902c90fE8BDB23D5FDcD36D0a46Ef93";

  const HonorController = await hre.ethers.getContractFactory("contracts/Finance/HonorController.sol:HonorController");
  const honorController = await HonorController.deploy(masterChef,honor);

  await honorController.deployed();


  console.log(
    `HonorController  deployed to ${honorController.address} }`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
