const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")
let { initialAdmin, busdAddr, aggrAddr, blbAddr, blbIoAddr } = require("./utils/cont.config.js")

  async function deployFarm() {
    const delay = ms => new Promise(res => setTimeout(res, ms));

    const investPlanAmounts = [
      ethers.utils.parseEther("100"), 
      ethers.utils.parseEther("1000"), 
      ethers.utils.parseEther("10000"), 
      ethers.utils.parseEther("50000")
    ]
    const investPlanProfits = [300, 500, 800, 1200] // denominator is 10,000

    // // BLBFarm
    // const Farm = await ethers.getContractFactory("FarmBLB");
    // const farm = await Farm.deploy(
    //   busdAddr, 
    //   blbAddr, 
    //   blbIoAddr, 
    //   investPlanAmounts, 
    //   investPlanProfits
    // );
    // await farm.deployed();
    // console.log("Farm Contract Address:", farm.address); 

    // await delay(10000)
    // await farm.transferOwnership(initialAdmin)
    // console.log("ownership transfered")

    await verify("0xBe033B3c363271c559286524A24BEf2ff40d4ec1", [
      busdAddr, 
      blbAddr, 
      blbIoAddr,
      investPlanAmounts, 
      investPlanProfits
    ])
    // await verify(stBNB.address, [blbAddr])
  }
    
  deployFarm();