const { ethers } = require("hardhat");

  async function main() {
    // simple deploy
    const ERC20Test = await ethers.getContractFactory("ERC20Test");
    const ET = await ERC20Test.deploy();
    await ET.deployed();
    console.log("ERC20Test Contract Address:", ET.address); 
  }
    
  main();