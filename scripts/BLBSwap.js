const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")
let { busdAddr, aggrAddr, blbAddr, initialAdmin } = require("./utils/cont.config.js")

  async function deployBLBSwap() {

    const BLBsPerUSD  = (100  * 10 ** 18).toString() //equals 100  BLB

    // simple deploy
    const BLBSwap = await ethers.getContractFactory("BLBSwap");
    const swap = await BLBSwap.deploy(BLBsPerUSD);
    await swap.deployed();
    console.log("BLBSwap Contract Address:", swap.address); 

    // verify on bscscan
    await verify(swap.address, [BLBsPerUSD])
  }
    
  deployBLBSwap();