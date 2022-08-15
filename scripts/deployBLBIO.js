const { ethers } = require("hardhat");

  async function main() {
    // simple deploy
    const BLBIO = await ethers.getContractFactory("BLBIO");
    const ICO = await BLBIO.deploy();
    await ICO.deployed();
    console.log("BLBIO Contract Address:", ICO.address); 
  }
    
  main();