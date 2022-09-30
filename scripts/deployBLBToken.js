const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")

  async function deployBLBToken() {
    // simple deploy
    const month = 2592000;
    const BLBToken = await ethers.getContractFactory("BLBToken");
    const BLB = await BLBToken.deploy(month);
    await BLB.deployed();
    console.log("BLBToken Contract Address:", BLB.address);
    
    await verify(BLB.address, [month])
  }   
  deployBLBToken()
  exports.deployBLBToken = deployBLBToken
