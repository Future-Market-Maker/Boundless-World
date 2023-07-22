const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")
let { initialAdmin, busdAddr, aggrAddr, blbAddr, blbIoAddr } = require("./utils/cont.config.js")

  async function deployStaking() {
    const delay = ms => new Promise(res => setTimeout(res, ms));

    // BLBStake
    const StakeBLB_BLB = await ethers.getContractFactory("StakeBLB_BLB");
    const stBLB = await StakeBLB_BLB.deploy(busdAddr, blbAddr, blbIoAddr);
    await stBLB.deployed();
    console.log("StakeBLB_BLB Contract Address:", stBLB.address); 

    await delay(10000)
    await stBLB.transferOwnership(initialAdmin)

    // // BNBStake
    // const StakeBNB_BLB = await ethers.getContractFactory("StakeBNB_BLB");
    // const stBNB = await StakeBNB_BLB.deploy(blbAddr);
    // await stBNB.deployed();
    // console.log("StakeBNB_BLB Contract Address:", stBNB.address); 

    await verify(stBLB.address, [busdAddr, blbAddr, blbIoAddr])
    // await verify(stBNB.address, [blbAddr])
  }
    
  deployStaking();