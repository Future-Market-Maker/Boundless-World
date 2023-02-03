/* global describe it before ethers */

const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { assert, expect } = require('chai')

describe('TransactionFeeTest', async function () {

    const hour = 60 * 60;
    let zero_address
    let deployer, user1, user2
    let BLBAddr
    let BLB
    let StakeBNB_BLBAddr
    let StakeBNB_BLB


    before(async function () {
        zero_address = "0x0000000000000000000000000000000000000000"
        const accounts = await ethers.getSigners();
        [deployer, user1, user2] = accounts
        
        BLB = await hre.ethers.getContractFactory("BLBToken");
        BLBAddr = await BLB.deploy(deployer.address);
        
        StakeBNB_BLB = await hre.ethers.getContractFactory("StakeBNB_BLB");
        StakeBNB_BLBAddr = await StakeBNB_BLB.deploy(BLBAddr.address);
    }) 

    it('check attributes after deploy', async () => {
        console.log(await StakeBNB_BLBAddr.plans())
    })



    it('the first invest of user1', async () => {
        await StakeBNB_BLBAddr.connect(user1).newInvestment(24 * hour, {value : ethers.utils.parseEther("1")})
        let pending = await StakeBNB_BLBAddr.pendingWithdrawal(user1.address, 0)
        assert.equal(pending[0], ethers.utils.parseEther("0.8").toString())
        assert.equal(pending[1], ethers.utils.parseEther("0").toString())
        await time.increase(12 * hour)
        pending = await StakeBNB_BLBAddr.pendingWithdrawal(user1.address, 0)
        assert.equal(pending[0], ethers.utils.parseEther("1").toString())
        assert.equal(pending[1], ethers.utils.parseEther("0").toString())
        await time.increase(8 * hour)
        pending = await StakeBNB_BLBAddr.pendingWithdrawal(user1.address, 0)
        assert.equal(pending[0], ethers.utils.parseEther("1").toString())
        assert.equal(pending[1], ethers.utils.parseEther("0.4").toString())
        await time.increase(4 * hour)
        pending = await StakeBNB_BLBAddr.pendingWithdrawal(user1.address, 0)
        assert.equal(pending[0], ethers.utils.parseEther("1").toString())
        assert.equal(pending[1], ethers.utils.parseEther("1").toString())
    })

    it('the second invest of user1', async () => {
        await StakeBNB_BLBAddr.connect(user1).newInvestment(7 * 24 * hour, {value : ethers.utils.parseEther("1")})
        let pending = await StakeBNB_BLBAddr.pendingWithdrawal(user1.address, 1)
        assert.equal(pending[0], ethers.utils.parseEther("0.8").toString())
        assert.equal(pending[1], ethers.utils.parseEther("0").toString())
        // console.log(await StakeBNB_BLBAddr.userInvestments(user1.address))

    //     assert.equal(await StakeBNB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("0.8").toString())
        await time.increase(4 * 24 * hour)
    //     assert.equal(await StakeBNB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("1").toString())
        await time.increase(2 * 24 * hour)
    //     assert.equal(await StakeBNB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("1.04").toString())
        await time.increase(24 * hour)
    //     assert.equal(await StakeBNB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("1.1").toString())
    //     console.log(await StakeBNB_BLBAddr.userInvestments(user1.address))
    })

    it('the first withdraw of user1', async () => {
        console.log(await ethers.provider.getBalance(user1.address))
        await BLBAddr.mint(StakeBNB_BLBAddr.address, ethers.utils.parseEther("20"))
        // console.log(await BLBAddr.balanceOf(user1.address))
        await StakeBNB_BLBAddr.connect(user1).withdraw(0)
        // console.log(await StakeBNB_BLBAddr.userInvestments(user1.address))

        console.log(await ethers.provider.getBalance(user1.address))
        console.log(await BLBAddr.balanceOf(user1.address))

    //     // assert.equal(await StakeBNB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("0.8").toString())
    //     // await time.increase(4 * 24 * hour)
    //     // assert.equal(await StakeBNB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("1").toString())
    //     // await time.increase(2 * 24 * hour)
    //     // assert.equal(await StakeBNB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("1.04").toString())
    //     // await time.increase(24 * hour)
    //     // assert.equal(await StakeBNB_BLBAddr.pendingWithdrawal(user1.address, 1), ethers.utils.parseEther("1.1").toString())
    //     // console.log(await StakeBNB_BLBAddr.userInvestments(user1.address))
    })


})
