const { ethers } = require("hardhat");

  async function main() {
    // simple deploy
    const BnbStaking = await ethers.getContractFactory("BnbStaking");
    const st = await BnbStaking.deploy();
    await st.deployed();
    console.log("BnbStaking Contract Address:", st.address); 
  }
    
  main();