const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")

  async function deployBLBIO() {

    // //addresses on bsc testnet
    // const BLB_Addr = "0x984D5774d9Bd67f77B6025fFEe1f773aE678E400"
    // const BUSD_Addr = "0xCd57b180aeA8B61C7b273785748988A3A8eAb9c2"
    // const AGGREGATOR_BNB_USD_Addr = "0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526"

    //addresses on bsc mainnet
    const BLB_Addr = "0x13D67Fd10BDBe8301E978e4AdCBD2c0AD26F7549"
    const BUSD_Addr = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"
    const AGGREGATOR_BNB_USD_Addr = "0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE"

    const publicBLBsPerUSD  = (30  * 10 ** 18).toString() //equals 30  BLB
    const privateBLBsPerUSD = (35  * 10 ** 18).toString() //equals 35  BLB
    const retailLimitUSD    = (500 * 10 ** 18).toString() //equals 500 USD
    const minimumUSDLimit   = (50  * 10 ** 18).toString() //equals 50  USD

    // simple deploy
    const BLBIO = await ethers.getContractFactory("BLBIO");
    const IO = await BLBIO.deploy(
      BLB_Addr, 
      BUSD_Addr, 
      AGGREGATOR_BNB_USD_Addr, 
      publicBLBsPerUSD, 
      privateBLBsPerUSD, 
      retailLimitUSD,
      minimumUSDLimit
    );
    await IO.deployed();
    console.log("BLBIO Contract Address:", IO.address); 

    // verify on bscscan
    await verify(IO.address, [
      BLB_Addr, 
      BUSD_Addr, 
      AGGREGATOR_BNB_USD_Addr, 
      publicBLBsPerUSD, 
      privateBLBsPerUSD, 
      retailLimitUSD,
      minimumUSDLimit
    ])
  }
    
  deployBLBIO();