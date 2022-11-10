/* global describe it before ethers */

const { assert, expect } = require('chai')

describe('TransactionFeeTest', async function () {

    let zero_address
    let deployer, user1, user2
    let BLBAddr
    let BLB

    before(async function () {
        zero_address = "0x0000000000000000000000000000000000000000"
        const accounts = await ethers.getSigners();
        [deployer, user1, user2] = accounts
        BLB = await hre.ethers.getContractFactory("BLBToken");
        BLBAddr = await BLB.deploy(deployer.address);
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

        await BLBAddr.connect(user1).setTransactionFee(0, 0, user1.address)
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

    it('no transaction fee for minter role to mint but transfer', async () => {
        await BLBAddr.setTransactionFee(1, 0, zero_address)

        let minterRole = await BLBAddr.MINTER_ROLE()
        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            0
        )

        await BLBAddr.grantRole(
            minterRole, user1.address
        )

        await BLBAddr.connect(user1).mint(user1.address, 101)

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            101
        )

        await BLBAddr.connect(user1).transfer(user2.address, 100)

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
           0
        )

        assert.equal(
            await BLBAddr.balanceOf(user2.address),
            100
        )

        await BLBAddr.revokeRole(
            minterRole, user1.address
        )
    })

    it('should not transfer whole when there is a transaction fee', async () => {
        await BLBAddr.setTransactionFee(1, 0, zero_address)
        assert.equal(
            await BLBAddr.transactionFee(100),
            1
        )
        await BLBAddr.setMonthlyTransferLimit(1000000)
        await expect(
            BLBAddr.connect(user2).transfer(user1.address, 100)
        ).to.be.revertedWith("ERC20: transfer amount exceeds balance")
    })

    it('should burn transaction fee', async () => {
        await BLBAddr.setTransactionFee(1, 0, zero_address)
        assert.equal(
            await BLBAddr.transactionFee(100),
            1
        )

        assert.equal(
            await BLBAddr.balanceOf(user2.address),
            100
        )
        await BLBAddr.connect(user2).transfer(user1.address, 10)

        assert.equal(
            await BLBAddr.balanceOf(user2.address),
            89
        )

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            10
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
            78
        )

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            20
        )

        assert.equal(
            await BLBAddr.balanceOf(deployer.address),
            1
        )
    })

    it('from address should pay transaction fee', async () => {
        await BLBAddr.setTransactionFee(1, 0, zero_address)
        assert.equal(
            await BLBAddr.transactionFee(100),
            1
        )
        await BLBAddr.connect(user1).approve(user2.address, 10)

        await BLBAddr.connect(user2).transferFrom(user1.address, deployer.address, 10)

        assert.equal(
            await BLBAddr.balanceOf(user2.address),
            78
        )

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            9
        )

        assert.equal(
            await BLBAddr.balanceOf(deployer.address),
            11
        )
    })


    it('fees should not be deducted from restricted addresses spendable fund', async () => {
        await BLBAddr.setTransactionFee(1, 0, zero_address)
        assert.equal(
            await BLBAddr.transactionFee(100),
            1
        )
        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            9
        )
        await BLBAddr.restrict(user1.address, 9)

        assert.equal(
            await BLBAddr.canSpend(user1.address),
            9
        )

        await BLBAddr.connect(user1).transfer(user2.address, 8)

        assert.equal(
            await BLBAddr.canSpend(user1.address),
            1
        )
        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            0
        )
        await BLBAddr.district(user1.address)
    })

    it('fees should not be deducted from monthly limit', async () => {
        await BLBAddr.setTransactionFee(1, 0, zero_address)
        
        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            0
        )

        await BLBAddr.setMonthlyTransferLimit(500000)

        await BLBAddr.mint(user1.address, 10)

        assert.equal(
            await BLBAddr.canSpend(user1.address),
            5
        )

        await BLBAddr.connect(user1).transfer(user2.address, 5)

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            4
        )
        assert.equal(
            await BLBAddr.canSpend(user1.address),
            0
        )
    })
})
