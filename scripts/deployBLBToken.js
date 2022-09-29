const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")

  async function deployBLBToken() {
    // simple deploy
    const BLBToken = await ethers.getContractFactory("BLBToken");
    const BLB = await BLBToken.deploy();
    await BLB.deployed();
    console.log("BLBToken Contract Address:", BLB.address);
    
    // await verify(BLB.address, )

    return BLB.address
  }   
  
  exports.deployBLBToken = deployBLBToken
