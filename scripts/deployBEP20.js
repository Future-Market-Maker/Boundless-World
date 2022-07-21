const { ethers, upgrades } = require("hardhat");

  async function main() {
    // simple deploy
    const BLBToken = await ethers.getContractFactory("BLBToken");
    const BLB = await BLBToken.deploy();
    await BLB.deployed();
    console.log("BLBToken Contract Address:", BLB.address); 
  }
    
  main();