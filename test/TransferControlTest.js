/* global describe it before ethers */

const { assert, expect } = require('chai')
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe('TransferControlTest', async function () {

    const month = 30 * 24 * 60 * 60;
    let zero_address
    let deployer, user1, user2, router
    let BLBAddr
    let BLB

    before(async function () {
        zero_address = "0x0000000000000000000000000000000000000000"
        const accounts = await ethers.getSigners();
        [deployer, user1, user2, router] = accounts
        BLB = await hre.ethers.getContractFactory("BLBToken");
        BLBAddr = await BLB.deploy(deployer.address);
    })

    it('only admin can set monthly fraction', async () => {
        let transferLimitSetter = await BLBAddr.TRANSFER_LIMIT_SETTER()

        assert.equal(
            await BLBAddr.hasRole(transferLimitSetter, user1.address),
            false
        )

        await expect(
            BLBAddr.connect(user1).setMonthlyTransferLimit(10)
        ).to.be.revertedWith("AccessControl")

        await BLBAddr.grantRole(
            transferLimitSetter, user1.address
        )

        assert.equal(
            await BLBAddr.hasRole(transferLimitSetter, user1.address),
            true
        )

        await BLBAddr.connect(user1).setMonthlyTransferLimit(10)
    })

    it('monthly fraction should be up to 100%', async () => {
        await expect(
            BLBAddr.setMonthlyTransferLimit(1000001)
        ).to.be.revertedWith("maximum fraction is 10**6 (equal to 100%)")

        await BLBAddr.setMonthlyTransferLimit(100000)
    })

    it('restricted address cannot spend more than its limitation', async () => {

        await BLBAddr.setMonthlyTransferLimit(1000000)

        await BLBAddr.mint(user1.address, 30)

        assert.equal(
            await BLBAddr.canSpend(user1.address),
            30
        )

        await BLBAddr.connect(user1).transfer(user2.address, 10)

        assert.equal(
            await BLBAddr.canSpend(user1.address),
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

        assert.equal(
            await BLBAddr.canSpend(user1.address),
            10
        )

        await BLBAddr.connect(user1).transfer(user2.address, 10)

        assert.equal(
            await BLBAddr.canSpend(user1.address),
            0
        )

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            0
        )
    })

    it('regular user can spend certain maximum fraction every month', async () => {
        await BLBAddr.setMonthlyTransferLimit(500000)

        let minterRole = await BLBAddr.MINTER_ROLE()
        assert.equal(
            await BLBAddr.hasRole(minterRole, user1.address),
            false
        )
        assert.equal(
            await BLBAddr.transactionFee(10),
            0
        )

        assert.equal(
            await BLBAddr.isRestricted(user1.address),
            false
        )
        await BLBAddr.mint(user1.address, 10)

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            10
        )
        assert.equal(
            await BLBAddr.canSpend(user1.address),
            5
        )

        await expect(
            BLBAddr.connect(user1).transfer(user2.address, 10)
        ).to.be.revertedWith("TransferControl: amount exceeds monthly spend limit")

        await BLBAddr.connect(user1).transfer(user2.address, 5)

        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            5
        )

        assert.equal(
            await BLBAddr.canSpend(user1.address),
            0
        )
        
        await expect(
            BLBAddr.connect(user1).transfer(user2.address, 1)
        ).to.be.revertedWith("TransferControl: amount exceeds monthly spend limit")

        await time.increase(1 * month);

        assert.equal(
            await BLBAddr.canSpend(user1.address),
            2
        )

        await BLBAddr.connect(user1).transfer(user2.address, 1)

        assert.equal(
            await BLBAddr.canSpend(user1.address),
            1
        )
        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            4
        )

        await BLBAddr.mint(user1.address, 10)

        assert.equal(
            await BLBAddr.canSpend(user1.address),
            6
        )
        assert.equal(
            await BLBAddr.balanceOf(user1.address),
            14
        )
    })

    it('router can take blb if restricted', async () => {

        assert.equal(
            await BLBAddr.canSpend(router.address),
            0
        )

        await BLBAddr.mint(deployer.address, 10)

        await BLBAddr.restrict(router.address, 20)

        await BLBAddr.approve(router.address, 10)

        await BLBAddr.connect(router).transferFrom(deployer.address, router.address, 10)

        await BLBAddr.connect(router).burn(10)
        assert.equal(
            await BLBAddr.balanceOf(router.address),
            0
        )
    })

    it('router router should not pay transaction fee if restricted', async () => {

        assert.equal(
            await BLBAddr.canSpend(router.address),
            0
        )
        await BLBAddr.setTransactionFee(1, 0, zero_address)

        await BLBAddr.mint(deployer.address, 11)

        await BLBAddr.restrict(router.address, 20)

        await BLBAddr.approve(router.address, 10)

        await BLBAddr.connect(router).transferFrom(deployer.address, router.address, 10)
    })



})
