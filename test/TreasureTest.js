const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
const { ethers } = require("hardhat");



const HonorTreseureAddress="0xFd4355C15e0F3Daf7f07FE208AA3502EabeF77DF";
const financeBUSDAddress="0x933Ac07385bA32ed43241f9DfD38C018Aa53433F";
const busdAddress="0x388672B44fD9370EAae35Ccc7A4a32F10b54da62";
const honorAddress="0x37CA99B38902c90fE8BDB23D5FDcD36D0a46Ef93";
const router1Address="0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
const router2Address="0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3";

function parseETH(val) {
    return ethers.utils.parseEther(val);
}
async function getBlock() {
    return await ethers.provider.getBlock("latest")
   }
    

async function getERC20(tokenAddress,signer) {
    const erc20=await ethers.getContractAt("contracts/Helpers/IERC20.sol:IERC20",tokenAddress,signer);

    return erc20;
}

  

  describe("Test BSC",  function() {

    it("Test Token",async function() {
        const [signer]=await ethers.getSigners();

        const busdToken=await getERC20(busdAddress);
        const honorToken=await getERC20(honorAddress);

      /*
        const hnrTreasure=await ethers.getContractFactory("contracts/HonorTreasure.sol:HonorTreasure");
        const honorTreasure=hnrTreasure.attach(HonorTreseureAddress);
       

        const  tx=await busdToken.approve(HonorTreseureAddress,parseETH("100000"));
        await tx.wait();

        
        const tx2=await honorTreasure.setRouters(router1Address,router2Address);
        await tx2.wait();

        
        const tx1=await honorToken.transfer(HonorTreseureAddress,parseETH("100"));
        await tx1.wait();


        const allowance=await busdToken.allowance(signer.address,HonorTreseureAddress);
        console.log("Allowance:" + allowance);

       
        const amount=parseETH("10");
   
        const tx5=await honorTreasure.depositBUSDLast(amount,{gasLimit:3000000});
        
        await tx5.wait();
        
      */
     await busdToken.approve(HonorTreseureAddress,parseETH("10000000"));
      await honorToken.transfer(HonorTreseureAddress,parseETH("5000"));
    })
    


 
    it("TestBaşlasın",async function () {
      
      /*
        const contract=await ethers.getContractAt("ISwapRouter",router1Address);
        console.log(contract);

        const contract1=await ethers.getContractAt("ISwapRouter",router2Address);
        console.log(contract1);

        const factory1=await contract.factory();
        console.log(factory1);

        const factory2=await contract1.factory();
        console.log(factory2);
        */
    })
 
  })