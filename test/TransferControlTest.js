/* global describe it before ethers */

const { assert, expect } = require('chai')

describe('TransferControlTest', async function () {

    const period = 3;
    let zero_address
    let deployer, user1, user2
    let BLBAddr
    let BLB

    before(async function () {
        zero_address = "0x0000000000000000000000000000000000000000"
        const accounts = await ethers.getSigners();
        [deployer, user1, user2] = accounts
        BLB = await hre.ethers.getContractFactory("BLBToken");
        BLBAddr = await BLB.deploy(period);
    }) 

    it('period fraction should be up to 100%', async () => {
        await expect(
            BLBAddr.setPeriodTransferFraction(1000001)
        ).to.be.revertedWith("maximum fraction is 10**6 (equal to 100%)")

        await BLBAddr.setPeriodTransferFraction(100000)
    })

    it('only admin can set period fraction', async () => {
        let transferLimitSetter = await BLBAddr.TRANSFER_LIMIT_SETTER()

        assert.equal(
            await BLBAddr.hasRole(transferLimitSetter, user1.address),
            false
        )

        await expect(
            BLBAddr.connect(user1).setPeriodTransferFraction(10)
        ).to.be.revertedWith("AccessControl")

        await BLBAddr.grantRole(
            transferLimitSetter, user1.address
        )

        assert.equal(
            await BLBAddr.hasRole(transferLimitSetter, user1.address),
            true
        )

        await BLBAddr.connect(user1).setPeriodTransferFraction(10)
    })

    it('period fraction should be up to 100%', async () => {
        await expect(
            BLBAddr.setPeriodTransferFraction(1000001)
        ).to.be.revertedWith("maximum fraction is 10**6 (equal to 100%)")

        await BLBAddr.setPeriodTransferFraction(100000)
    })

    it('restricted address cannot spend more than its limitation', async () => {

        await BLBAddr.setPeriodTransferFraction(1000000)

        await BLBAddr.mint(user1.address, 30)

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            30
        )

        await BLBAddr.connect(user1).transfer(user2.address, 10)

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            20
        )

        await BLBAddr.restrict(user1.address, 10)

        await expect(
            BLBAddr.connect(user1).transfer(user2.address, 11)
        ).to.be.revertedWith("TransferControl: amount exceeds spend limit")

        await BLBAddr.connect(user1).transfer(user2.address, 10)

        await expect(
            BLBAddr.connect(user1).transfer(user2.address, 1)
        ).to.be.revertedWith("TransferControl: amount exceeds spend limit")

        await BLBAddr.district(user1.address)

        await BLBAddr.connect(user1).transfer(user2.address, 10)

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            0
        )
    })

    it('minter role can also be restricted', async () => {
        let minterRole = await BLBAddr.MINTER_ROLE()

        await BLBAddr.grantRole(
            minterRole, user1.address
        )

        await BLBAddr.connect(user1).mint(user1.address, 30)

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            30
        )

        await BLBAddr.restrict(user1.address, 10)

        BLBAddr.connect(user1).mint(user2.address, 10)

        await expect(
            BLBAddr.connect(user1).mint(user2.address, 10)
        ).to.be.revertedWith("TransferControl: amount exceeds spend limit")

        await BLBAddr.district(user1.address)

        BLBAddr.connect(user1).mint(user2.address, 10)
    })



})
