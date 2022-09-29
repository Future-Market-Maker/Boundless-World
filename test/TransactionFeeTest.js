/* global describe it before ethers */

// const { ethers } = require("hardhat")

const { assert, expect } = require('chai')

describe('TransactionFeeTest', async function () {
    const multiplier = 10 ** 18

    let zero_address = "0x0000000000000000000000000000000000000000"
    let deployer, user1, user2
    let BLBAddr
    let BLB

    before(async function () {
        zero_address = "0x0000000000000000000000000000000000000000"
        const accounts = await ethers.getSigners();
        [deployer, user1, user2] = accounts
        BLB = await hre.ethers.getContractFactory("BLBToken");
        BLBAddr = await BLB.deploy();
    }) 

    it('only admin can set transaction fee', async () => {
        let feeSetterRole = await BLBAddr.TRANSACTION_FEE_SETTER()

        assert.equal(
            await BLBAddr.hasRole(feeSetterRole, user1.address),
            false
        )

        await expect(
            BLBAddr.connect(user1).setTransactionFee(0, 0, user1.address)
        ).to.be.revertedWith("AccessControl")

        await BLBAddr.connect(deployer).grantRole(
            feeSetterRole, user1.address
        )

        assert.equal(
            await BLBAddr.hasRole(feeSetterRole, user1.address),
            true
        )

        BLBAddr.connect(user1).setTransactionFee(0, 0, user1.address)
    })

    it('cannot not set feeAmount and feeFraction at the same time', async () => {
        await expect(
            BLBAddr.setTransactionFee(10, 10, deployer.address)
        ).to.be.revertedWith("TransactionFee: Cannot set feeAmount and feeFraction at the same time")
    })

    it('should set up to 10% transaction fee fraction', async () => {
        await expect(
            BLBAddr.setTransactionFee(0, 100001, user1.address)
        ).to.be.revertedWith("TransactionFee: Up to 10% transactionFee can be set")

    })

    it('check transaction fee by fee fraction', async () => {
        await BLBAddr.setTransactionFee(0, 100000, user1.address)

        assert.equal(
            await BLBAddr.transactionFee(100),
            10
        )
    })

    it('check transaction fee by fee amount', async () => {
        await BLBAddr.setTransactionFee(1, 0, user1.address)
        
        assert.equal(
            await BLBAddr.transactionFee(100),
            1
        )
    })

    it('no transaction fee for minter role', async () => {
        let feeSetterRole = await BLBAddr.MINTER_ROLE()
        assert.equal(
            await BLBAddr.hasRole(feeSetterRole, user1.address),
            false
        )
        await BLBAddr.grantRole(
            feeSetterRole, user1.address
        )
        assert.equal(
            await BLBAddr.hasRole(feeSetterRole, user1.address),
            true
        )
        await BLBAddr.connect(user1).mint(user1.address, 100)

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            100
        )

        await BLBAddr.connect(user1).transfer(user2.address, 40)

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            60
        )

        assert.equal(
            await BLBAddr.balanceOf(user2.address),
            40
        )
    })

    it('should not transfer whole when there is a transaction fee', async () => {
        await BLBAddr.setTransactionFee(1, 0, zero_address)
        assert.equal(
            await BLBAddr.transactionFee(100),
            1
        )
        await BLBAddr.setPeriodTransferFraction(1000000)
        await expect(
            BLBAddr.connect(user2).transfer(user1.address, 40)
        ).to.be.revertedWith("ERC20: transfer amount exceeds balance")
    })

    it('should burn transaction fee', async () => {
        await BLBAddr.setTransactionFee(1, 0, zero_address)
        assert.equal(
            await BLBAddr.transactionFee(100),
            1
        )
        await BLBAddr.connect(user2).transfer(user1.address, 20)

        assert.equal(
            await BLBAddr.balanceOf(user2.address),
            19
        )

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            80
        )
    })

    it('should send transaction fee to deployer', async () => {
        await BLBAddr.setTransactionFee(1, 0, deployer.address)
        assert.equal(
            await BLBAddr.transactionFee(100),
            1
        )
        await BLBAddr.connect(user2).transfer(user1.address, 10)

        assert.equal(
            await BLBAddr.balanceOf(user2.address),
            8
        )

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            90
        )

        assert.equal(
            await BLBAddr.balanceOf(deployer.address),
            1
        )
    })

    
})
