const { ethers } = require("hardhat");

  async function deployBLBToken() {
    // simple deploy
    const BLBToken = await ethers.getContractFactory("BLBToken");
    const BLB = await BLBToken.deploy();
    await BLB.deployed();
    console.log("BLBToken Contract Address:", BLB.address);
    return BLB.address
  }   
  
  module.exports = async ({ getNamedAccounts, deployments }) => {
    
  deployBLBToken()

  exports.deployBLBToken = deployBLBToken
