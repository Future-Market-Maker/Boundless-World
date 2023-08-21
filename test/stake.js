/* global describe it before ethers */

const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { assert, expect } = require('chai')

describe('TransactionFeeTest', async function () {

    let zero_address;

    let day = 60 * 60 * 24

    let busd;
    let blb;
    let blbSwap;
    let durationInDays;
    let investPlanProfits;
    let farm;

    before(async function () {
        zero_address = "0x0000000000000000000000000000000000000000"
        const accounts = await ethers.getSigners();
        [deployer, user1, user2] = accounts
        
        const BUSD = await hre.ethers.getContractFactory("BUSDTest");
        busd = await BUSD.deploy();
        
        const BLB = await hre.ethers.getContractFactory("BUSDTest");
        blb = await BLB.deploy();

        const BLBSwap = await hre.ethers.getContractFactory("TestBLBSwap")
        blbSwap = await BLBSwap.deploy();
        durationInDays = [3, 10, 30, 90, 180, 360]
        profitPlans = [
            ethers.utils.parseEther("0.001"), 
            ethers.utils.parseEther("0.04"), 
            ethers.utils.parseEther("0.15"), 
            ethers.utils.parseEther("0.5"), 
            ethers.utils.parseEther("1.2"),
            ethers.utils.parseEther("2.5")
        ]
    })

    it('deploy farm', async () => {
        const Farm = await hre.ethers.getContractFactory("FarmBLB")
        farm = await Farm.deploy(
            busd.address,
            blb.address,
            blbSwap.address,
            profitPlans,
            investPlanProfits
        );
    })
})
