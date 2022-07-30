const { ethers } = require("hardhat");

  async function main() {
    // simple deploy
    const LPToken = await ethers.getContractFactory("LPToken");
    const LP = await LPToken.deploy();
    await LP.deployed();
    console.log("LPToken Contract Address:", LP.address); 
  }
    
  main();