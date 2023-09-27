const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")
let { busdAddr, aggrAddr, blbAddr, initialAdmin } = require("./utils/cont.config.js")

  async function deployBLBSwap() {
    const delay = ms => new Promise(res => setTimeout(res, ms));

    const BLBsPerUSD  = (100  * 10 ** 18).toString() //equals 100  BLB

    // simple deploy
    const BLBSwap = await ethers.getContractFactory("BLBSwap");
    const swap = await BLBSwap.deploy(BLBsPerUSD, blbAddr, busdAddr);
    await swap.deployed();
    console.log("BLBSwap Contract Address:", swap.address); 

    await swap.transferOwnership(initialAdmin);
    console.log("initilize admin")

    // verify on bscscan
    await delay(20000)
    await verify(swap.address, [BLBsPerUSD, blbAddr, busdAddr])
  }
    
  deployBLBSwap();