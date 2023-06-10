const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")
let { blbAddr, initialAdmin } = require("./utils/cont.config.js")

  async function deployBLBToken() {
    
    const BLBToken = await ethers.getContractFactory("BLBToken");
    const BLB = await BLBToken.deploy(initialAdmin);
    await BLB.deployed();
    console.log("BLBToken Contract Address:", BLB.address);
    
    await verify(BLB.address, [initialAdmin])
  }   
  
  deployBLBToken()
