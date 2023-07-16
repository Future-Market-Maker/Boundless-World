const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")
let { busdAddr, aggrAddr, blbAddr, initialAdmin } = require("./utils/cont.config.js")

  async function deployBLBIO() {

    const publicBLBsPerUSD  = (30  * 10 ** 18).toString() //equals 30  BLB
    const privateBLBsPerUSD = (35  * 10 ** 18).toString() //equals 35  BLB
    const retailLimitUSD    = (500 * 10 ** 18).toString() //equals 500 USD
    const minimumUSDLimit   = (50  * 10 ** 18).toString() //equals 50  USD

    // simple deploy
    const BLBIO = await ethers.getContractFactory("BLBIO");
    const IO = await BLBIO.deploy(
      blbAddr, 
      busdAddr, 
      aggrAddr, 
      publicBLBsPerUSD, 
      privateBLBsPerUSD, 
      retailLimitUSD,
      minimumUSDLimit
    );
    await IO.deployed();
    console.log("BLBIO Contract Address:", IO.address); 

    // verify on bscscan
    await verify(IO.address, [
      blbAddr, 
      busdAddr, 
      aggrAddr, 
      publicBLBsPerUSD, 
      privateBLBsPerUSD, 
      retailLimitUSD,
      minimumUSDLimit
    ])
  }
    
  deployBLBIO();