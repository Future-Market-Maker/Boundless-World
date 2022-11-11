const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")

  async function deployBLBToken() {
    
    // const initialAdmin = "0x31FBc230BC6b8cE2eE229eCfbACCc364Da3eD7fC";
    // const initialAdmin = "0xfd4299C480dEcE1f48e514e2D3c6F38815677106";
    const initialAdmin = "0xe189BfcC0D6f5f63401B104c1051699C7AA1ae4a";
    
    const BLBToken = await ethers.getContractFactory("BLBToken");
    const BLB = await BLBToken.deploy(initialAdmin);
    await BLB.deployed();
    console.log("BLBToken Contract Address:", BLB.address);
    
    await verify(BLB.address, [initialAdmin])
  }   
  deployBLBToken()
  exports.deployBLBToken = deployBLBToken
