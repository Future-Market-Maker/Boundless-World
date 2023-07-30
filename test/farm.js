/* global describe it before ethers */

const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { assert, expect } = require('chai')

describe('TransactionFeeTest', async function () {

    let zero_address;

    let day = 60 * 60 * 24

    let busd;
    let blb;
    let blbSwap;
    let investPlanAmounts;
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

        investPlanAmounts = [
            ethers.utils.parseEther("100"), 
            ethers.utils.parseEther("1000"), 
            ethers.utils.parseEther("10000"), 
            ethers.utils.parseEther("50000")
        ]
        investPlanProfits = [300, 500, 800, 1200]
    })


    it('deploy farm', async () => {
        const Farm = await hre.ethers.getContractFactory("FarmBLB")
        farm = await Farm.deploy(
            busd.address,
            blb.address,
            blbSwap.address,
            investPlanAmounts,
            investPlanProfits
        );
    })


    it('user1 claim test', async () => {
        await blb.mint(farm.address, ethers.utils.parseEther("100000000"))
        await busd.mint(user1.address, ethers.utils.parseEther("100000000"))
        await busd.connect(user1).approve(farm.address, ethers.utils.parseEther("100000000"))



        await farm.connect(user1).buyAndStake(ethers.utils.parseEther("100"))
        await farm.connect(user1).topUpPayable(ethers.utils.parseEther("100"), 0)

    await time.increase(30 * day);
    assert.equal(ethers.utils.formatEther(await farm.claimable(user1.address, 0)), 30)

        await farm.connect(user1).topUpPayable(ethers.utils.parseEther("800"), 0)

    await time.increase(30 * day);
    assert.equal(ethers.utils.formatEther(await farm.claimable(user1.address, 0)), 90)

    await farm.connect(user1).topUpPayable(ethers.utils.parseEther("4000"), 0)

    await time.increase(30 * day);
    assert.equal(ethers.utils.formatEther(await farm.claimable(user1.address, 0)), 590)
        
        await farm.connect(user1).topUpPayable(ethers.utils.parseEther("5000"), 0)

    await time.increase(30 * day);
    assert.equal(ethers.utils.formatEther(await farm.claimable(user1.address, 0)), 3090)
        

    await time.increase(30 * day);
    assert.equal(ethers.utils.formatEther(await farm.claimable(user1.address, 0)), 11090)
        

    await time.increase(5* 30 * day);
    assert.equal(ethers.utils.formatEther(await farm.claimable(user1.address, 0)), 51090)
    // console.log(ethers.utils.formatEther(await farm.pendingWithdrawalById(user1.address, 0)))

        await farm.connect(user1).topUpPayable(ethers.utils.parseEther("50000"), 0)
        
    await time.increase(30 * day);
    assert.equal(ethers.utils.formatEther(await farm.claimable(user1.address, 0)), 59090)
    
    // await farm.connect(user1).claimId(0)

    // await time.increase(30 * day);
    // assert.equal(ethers.utils.formatEther(await farm.claimable(user1.address, 0)), 131090)

    // console.log(ethers.utils.formatEther(await farm.pendingWithdrawalById(user1.address, 0)))
    
    await farm.connect(user1).withdraw(0)
    // await farm.connect(user1).withdraw(0)
    console.log(ethers.utils.formatEther(await farm.pendingWithdrawalById(user1.address, 0)))



    // await time.increase(30 * day); assert.equal(ethers.utils.formatEther(await farm.claimable(user1.address, 0)), 590)
    // console.log(ethers.utils.formatEther(await farm.userTotalStake(user1.address)))
    })


    // it('top up 1 BUSD', async () => {
    //     await busd.mint(user1.address, ethers.utils.parseEther("100"))
    //     await busd.connect(user1).approve(farm.address, ethers.utils.parseEther("100"))
    //     await farm.connect(user1).topUpPayable(ethers.utils.parseEther("100"), 0)

    //     console.log(ethers.utils.formatEther(await farm.claimable(user1.address, 0)))
    //     // console.log(await farm.userInvestments(user1.address))
    // })


    // it('user1 invest2 BNB', async () => {
    //     await farm.connect(user1).buyAndStake(0, {value : ethers.utils.parseEther("0.5")})

    //     // console.log(ethers.utils.formatEther(await farm.userTotalStake(user1.address)))
    // })


    // it('user1 invest3 BLB', async () => {
    //     await blb.mint(user1.address, ethers.utils.parseEther("1000"))
    //     await blb.connect(user1).approve(farm.address, ethers.utils.parseEther("1000"))
    //     await farm.connect(user1).newInvestment(ethers.utils.parseEther("1000"))

    //     // console.log(ethers.utils.formatEther(await farm.userTotalStake(user1.address)))
    // })


    // it('claimable 1', async () => {
    //     await time.increase(60 * day)
    //     // console.log(ethers.utils.formatEther(await farm.claimable(user1.address, 0)))
    // })


    // it('top up 1 BUSD', async () => {
    //     await busd.mint(user1.address, ethers.utils.parseEther("100"))
    //     await busd.connect(user1).approve(farm.address, ethers.utils.parseEther("100"))
    //     await farm.connect(user1).topUpPayable(ethers.utils.parseEther("100"), 0)

    //     // console.log(ethers.utils.formatEther(await farm.userTotalStake(user1.address)))
    //     // console.log(await farm.userInvestments(user1.address))
    // })


    // it('top up 2 BNB', async () => {        
    //     await farm.connect(user1).topUpPayable(0, 0, {value : ethers.utils.parseEther("0.5")})

    //     // console.log(ethers.utils.formatEther(await farm.userTotalStake(user1.address)))
    //     // console.log(await farm.userInvestments(user1.address))
    // })


    // it('top up 3 BLB', async () => {
    //     await blb.mint(user1.address, ethers.utils.parseEther("1000"))
    //     await blb.connect(user1).approve(farm.address, ethers.utils.parseEther("1000"))
    //     await farm.connect(user1).topUp(ethers.utils.parseEther("1000"), 0)

    //     console.log(ethers.utils.formatEther(await farm.userTotalStake(user1.address)))
    //     // console.log(await farm.userInvestments(user1.address))
    // })


    // it('claimable 1', async () => {
    //     await time.increase(60 * day)
    //     console.log(ethers.utils.formatEther(await farm.claimable(user1.address, 0)))
    // })









})
