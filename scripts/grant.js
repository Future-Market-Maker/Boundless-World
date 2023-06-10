const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")
let { blbAddr, initialAdmin } = require("./utils/cont.config.js")

  async function deployBLBToken() {
    
    const BLBToken = await ethers.getContractAt("BLBToken", blbAddr);
    console.log("BLBToken Contract Address:", BLBToken.address);

    console.log(await BLBToken.hasRole(await BLBToken.DEFAULT_ADMIN_ROLE(), "0x31FBc230BC6b8cE2eE229eCfbACCc364Da3eD7fC"))
  }   
  
  deployBLBToken()
