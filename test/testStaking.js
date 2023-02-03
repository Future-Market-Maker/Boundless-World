/* global describe it before ethers */

const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { assert, expect } = require('chai')

describe('TransactionFeeTest', async function () {

    const hour = 60 * 60;
    let zero_address
    let deployer, user1, user2
    let BLBAddr
    let BLB
    let StakeBLB_BLBAddr
    let StakeBLB_BLB


    before(async function () {
        zero_address = "0x0000000000000000000000000000000000000000"
        const accounts = await ethers.getSigners();
        [deployer, user1, user2] = accounts
        
        BLB = await hre.ethers.getContractFactory("BLBToken");
        BLBAddr = await BLB.deploy(deployer.address);
        
        StakeBLB_BLB = await hre.ethers.getContractFactory("StakeBLB_BLB");
        StakeBLB_BLBAddr = await StakeBLB_BLB.deploy(BLBAddr.address);
    }) 

    it('check attributes after deploy', async () => {
        // console.log(await StakeBLB_BLBAddr.plans())
    })



    it('the first invest of user1', async () => {
        await BLBAddr.mint(user1.address, ethers.utils.parseEther("20"))
        await BLBAddr.connect(user1).approve(StakeBLB_BLBAddr.address, ethers.utils.parseEther("1"))
        await StakeBLB_BLBAddr.connect(user1).newInvestment(ethers.utils.parseEther("1"), 86400)
        assert.equal(await StakeBLB_BLBAddr.pendingWithdrawal(user1.address, 0), ethers.utils.parseEther("0.8").toString())
        await time.increase(12 * hour)
        assert.equal(await StakeBLB_BLBAddr.pendingWithdrawal(user1.address, 0), ethers.utils.parseEther("1").toString())
        await time.increase(8 * hour)
        assert.equal(await StakeBLB_BLBAddr.pendingWithdrawal(user1.address, 0), ethers.utils.parseEther("1.004").toString())
        await time.increase(4 * hour)
        assert.equal(await StakeBLB_BLBAddr.pendingWithdrawal(user1.address, 0), ethers.utils.parseEther("1.01").toString())
        // console.log(await StakeBLB_BLBAddr.userInvestments(user1.address))

    })

    it('the second invest of user1', async () => {
        // await BLBAddr.mint(user1.address, ethers.utils.parseEther("20"))
        await BLBAddr.connect(user1).approve(StakeBLB_BLBAddr.address, ethers.utils.parseEther("1"))
        await StakeBLB_BLBAddr.connect(user1).newInvestment(ethers.utils.parseEther("1"), 7 * 24 * hour)
        // console.log(await StakeBLB_BLBAddr.userInvestments(user1.address))

        assert.equal(await StakeBLB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("0.8").toString())
        await time.increase(4 * 24 * hour)
        assert.equal(await StakeBLB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("1").toString())
        await time.increase(2 * 24 * hour)
        assert.equal(await StakeBLB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("1.04").toString())
        await time.increase(24 * hour)
        assert.equal(await StakeBLB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("1.1").toString())
        console.log(await StakeBLB_BLBAddr.userInvestments(user1.address))
    })

    it('the first withdraw of user1', async () => {
        // console.log(await ethers.provider.getBalance(user1.address))
        console.log(await BLBAddr.balanceOf(user1.address))
        await StakeBLB_BLBAddr.connect(user1).withdraw(0)
        // console.log(await StakeBLB_BLBAddr.userInvestments(user1.address))
        // console.log(await StakeBLB_BLBAddr.pendingWithdrawal(user1.address, 0))

        // console.log(await ethers.provider.getBalance(user1.address))
        console.log(await BLBAddr.balanceOf(user1.address))

        // assert.equal(await StakeBLB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("0.8").toString())
        // await time.increase(4 * 24 * hour)
        // assert.equal(await StakeBLB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("1").toString())
        // await time.increase(2 * 24 * hour)
        // assert.equal(await StakeBLB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("1.04").toString())
        // await time.increase(24 * hour)
        // assert.equal(await StakeBLB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("1.1").toString())
        // console.log(await StakeBLB_BLBAddr.userInvestments(user1.address))
    })


})
