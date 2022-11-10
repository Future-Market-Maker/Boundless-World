/* global describe it before ethers */

const { assert, expect } = require('chai')

describe('TransactionFeeTest', async function () {

    let zero_address
    let deployer, user1, user2
    let BLBAddr
    let BLB
    let BUSDAddr
    let BUSD
    let BLBIOAddr
    let BLBIO

    before(async function () {
        zero_address = "0x0000000000000000000000000000000000000000"
        const accounts = await ethers.getSigners();
        [deployer, user1, user2] = accounts
        
        BLB = await hre.ethers.getContractFactory("BLBToken");
        BLBAddr = await BLB.deploy(deployer.address);
        
        BUSD = await hre.ethers.getContractFactory("ERC20Test");
        BUSDAddr = await BLB.deploy("BUSD", "BUSD");

        BLBIO = await hre.ethers.getContractFactory("BLBIO");
        BLBIOAddr = await BLB.deploy(BLBAddr, BUSDAddr, zeroAddress);
    }) 

})
