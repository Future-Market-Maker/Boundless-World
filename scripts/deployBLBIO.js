const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")

  async function deployBLBIO() {

    //addresses on bsc testnet
    const BLB_Addr = "0x134341a04B11B1FD697Fc57Eab7D96bDbcdEa414"
    const BUSD_Addr = "0xCd57b180aeA8B61C7b273785748988A3A8eAb9c2"
    const AGGREGATOR_USD_BNB_Addr = "0x0630521aC362bc7A19a4eE44b57cE72Ea34AD01c"

    // //addresses on bsc mainnet
    // const BLB_Addr = "0x598cC4306b383c09521f079404bEd460831BDDCf"
    // const BUSD_Addr = "0x06E43af108E7d5F9c1172c5e4b61730C7642a8bC"
    // const AGGREGATOR_USD_BNB_Addr = "0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941"


    // simple deploy
    const BLBIO = await ethers.getContractFactory("BLBIO");
    const IO = await BLBIO.deploy(BLB_Addr, BUSD_Addr, AGGREGATOR_USD_BNB_Addr);
    await IO.deployed();
    console.log("BLBIO Contract Address:", IO.address); 

    await verify(IO.address, [BLB_Addr, BUSD_Addr, AGGREGATOR_USD_BNB_Addr])
  }
    
  deployBLBIO();