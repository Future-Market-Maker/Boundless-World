const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")

  async function deployStaking() {
    //BLB on testnet
    const blbAddr = "0x984D5774d9Bd67f77B6025fFEe1f773aE678E400"

    //BLB on mainnet
    // const blbAddr = "0x13D67Fd10BDBe8301E978e4AdCBD2c0AD26F7549"

    // BLBStake
    const StakeBLB_BLB = await ethers.getContractFactory("StakeBLB_BLB");
    const stBLB = await StakeBLB_BLB.deploy(blbAddr);
    await stBLB.deployed();
    console.log("StakeBLB_BLB Contract Address:", stBLB.address); 

    // BNBStake
    const StakeBNB_BLB = await ethers.getContractFactory("StakeBNB_BLB");
    const stBNB = await StakeBNB_BLB.deploy(blbAddr);
    await stBNB.deployed();
    console.log("StakeBNB_BLB Contract Address:", stBNB.address); 

    await verify(stBLB.address, [blbAddr])
    await verify(stBNB.address, [blbAddr])
  }
    
  deployStaking();