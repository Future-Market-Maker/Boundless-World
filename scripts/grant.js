const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")
let { blbAddr, initialAdmin } = require("./utils/cont.config.js")

  async function deployBUSDToken() {
    
    // const BUSD = await ethers.getContractFactory("BUSDTest");
    // const BUSDAddr = await BUSD.deploy();
    // await BUSDAddr.deployed();
    // console.log("BUSD : ", BUSDAddr.address);

    await verify("0x87cdBfc8531CE5C6f2f07abD0E6E46D06467BA0D",[])
  }   
  
  deployBUSDToken()
