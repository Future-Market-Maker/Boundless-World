const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")
let { initialAdmin, busdAddr, aggrAddr, blbAddr, blbIoAddr } = require("./utils/cont.config.js")

  async function deployStaking() {
    const delay = ms => new Promise(res => setTimeout(res, ms));

    const timePlans = [5, 30, 90, 180, 360] // in days
    const investPlanAmounts = [
      ethers.utils.parseEther("100"), 
      ethers.utils.parseEther("1000"), 
      ethers.utils.parseEther("10000"), 
      ethers.utils.parseEther("50000")
    ]
    const investPlanProfits = [300, 500, 800, 1200] // denominator is 10,000

    // BLBStake
    const StakeBLB_BLB = await ethers.getContractFactory("StakeBLB_BLB");
    const stBLB = await StakeBLB_BLB.deploy(
      busdAddr, 
      blbAddr, 
      blbIoAddr, 
      timePlans, 
      investPlanAmounts, 
      investPlanProfits
    );
    await stBLB.deployed();
    console.log("StakeBLB_BLB Contract Address:", stBLB.address); 

    await delay(10000)
    await stBLB.transferOwnership(initialAdmin)
    console.log("ownership transfered")

    // // BNBStake
    // const StakeBNB_BLB = await ethers.getContractFactory("StakeBNB_BLB");
    // const stBNB = await StakeBNB_BLB.deploy(blbAddr);
    // await stBNB.deployed();
    // console.log("StakeBNB_BLB Contract Address:", stBNB.address); 

    await verify(stBLB.address, [
      busdAddr, 
      blbAddr, 
      blbIoAddr,
      timePlans, 
      investPlanAmounts, 
      investPlanProfits
    ])
    // await verify(stBNB.address, [blbAddr])
  }
    
  deployStaking();