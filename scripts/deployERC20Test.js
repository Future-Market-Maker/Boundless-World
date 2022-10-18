const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js")

  async function main() {
    // simple deploy
    const ERC20Test = await ethers.getContractFactory("ERC20Test");
    const ET = await ERC20Test.deploy();
    await ET.deployed();
    console.log("ERC20Test Contract Address:", ET.address); 

    await verify(ET.address, [])

  }
    
  main();