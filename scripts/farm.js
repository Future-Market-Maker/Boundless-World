const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")
let { initialAdmin, busdAddr, aggrAddr, blbAddr, blbIoAddr, farmAddr } = require("./utils/cont.config.js")

  async function deployFarm() {
    const delay = ms => new Promise(res => setTimeout(res, ms));

    const investPlanAmounts = [
      ethers.utils.parseEther("100"), 
      ethers.utils.parseEther("500"), 
      ethers.utils.parseEther("1000"), 
      ethers.utils.parseEther("5000")
    ]
    const investPlanProfits = [350, 450, 600, 750] // denominator is 10,000

    // BLBFarm
    const Farm = await ethers.getContractFactory("FarmBLB");
    const farm = await Farm.deploy(
      busdAddr, 
      blbAddr, 
      blbIoAddr, 
      investPlanAmounts, 
      investPlanProfits
    );
    await farm.deployed();
    console.log("Farm Contract Address:", farm.address); 

    await delay(10000)
    await farm.transferOwnership(initialAdmin)
    console.log("ownership transfered")

    await verify(farm.address, [
      busdAddr, 
      blbAddr, 
      blbIoAddr,
      investPlanAmounts, 
      investPlanProfits
    ])

    // // change plan -------------------------------------------------------------

    // farm = await ethers.getContractAt("FarmBLB", farmAddr)

    // await farm.setInvestPlans(investPlanAmounts, investPlanProfits)
  }
    
  deployFarm();