const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")
let { initialAdmin, busdAddr, aggrAddr, blbAddr, blbIoAddr } = require("./utils/cont.config.js")

  async function deployStaking() {
    const delay = ms => new Promise(res => setTimeout(res, ms));

    durationInDays = [3, 10, 30, 90, 180, 360]
    profitPlans = [
        ethers.utils.parseEther("0.001"), 
        ethers.utils.parseEther("0.04"), 
        ethers.utils.parseEther("0.15"), 
        ethers.utils.parseEther("0.5"), 
        ethers.utils.parseEther("1.2"),
        ethers.utils.parseEther("2.5")
    ]

    // BLBStake
    const StakeBLB_BLB = await ethers.getContractFactory("StakeBLB_BLB");
    const stBLB = await StakeBLB_BLB.deploy(
      busdAddr, 
      blbAddr, 
      blbIoAddr,
      durationInDays,
      profitPlans
    );
    await stBLB.deployed();
    console.log("StakeBLB_BLB Contract Address:", stBLB.address); 

    await delay(10000)
    await stBLB.transferOwnership(initialAdmin)
    console.log("ownership transfered")

    await verify(stBLB.address, [
      busdAddr, 
      blbAddr, 
      blbIoAddr,
      durationInDays,
      profitPlans
    ])
  }
    
  deployStaking();