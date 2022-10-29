const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")

  async function deployBLBIO() {

    //addresses on bsc testnet
    const BLB_Addr = "0x134341a04B11B1FD697Fc57Eab7D96bDbcdEa414"
    const BUSD_Addr = "0xCd57b180aeA8B61C7b273785748988A3A8eAb9c2"
    const AGGREGATOR_USD_BNB_Addr = "0x0630521aC362bc7A19a4eE44b57cE72Ea34AD01c"

    // //addresses on bsc mainnet
    // const BLB_Addr = "0x3034e7400F7DE5559475a6f0398d26991f965ca3"
    // const BUSD_Addr = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"
    // const AGGREGATOR_USD_BNB_Addr = "0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941"


    // simple deploy
    const BLBIO = await ethers.getContractFactory("BLBIO");
    const IO = await BLBIO.deploy();
    await IO.deployed();
    console.log("BLBIO Contract Address:", IO.address); 

    await verify(IO.address)
  }
    
  deployBLBIO();