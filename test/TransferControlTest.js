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

    it('only admin can restrict and destrict', async () => {
        // let transferLimitSetter = await BLBAddr.TRANSFER_LIMIT_SETTER()

        // assert.equal(
        //     await BLBAddr.hasRole(transferLimitSetter, user1.address),
        //     false
        // )

        // await expect(
        //     BLBAddr.connect(user1).setPeriodTransferFraction(10)
        // ).to.be.revertedWith("AccessControl")

        // await BLBAddr.grantRole(
        //     transferLimitSetter, user1.address
        // )

        // assert.equal(
        //     await BLBAddr.hasRole(transferLimitSetter, user1.address),
        //     true
        // )

        // await BLBAddr.connect(user1).setPeriodTransferFraction(10)
    })


})
