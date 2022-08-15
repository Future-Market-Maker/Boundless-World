const { ethers } = require("hardhat");

  async function main() {
    // simple deploy
    const BLB_ICO = await ethers.getContractFactory("BLB_ICO");
    const ICO = await BLB_ICO.deploy();
    await ICO.deployed();
    console.log("BLB_ICO Contract Address:", ICO.address); 
  }
    
  main();