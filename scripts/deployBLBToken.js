const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")

  async function deployBLBToken() {
    // simple deploy
    const initialAdmin = 0x31FBc230BC6b8cE2eE229eCfbACCc364Da3eD7fC;

    const BLBToken = await ethers.getContractFactory("BLBToken");
    const BLB = await BLBToken.deploy(month, initialAdmin);
    await BLB.deployed();
    console.log("BLBToken Contract Address:", BLB.address);
    
    await verify(BLB.address, [month, initialAdmin])
  }   
  deployBLBToken()
  exports.deployBLBToken = deployBLBToken
