/* global describe it before ethers */

const { deployBLBToken } = require('../scripts/deployBLBToken.js')

const { network, getNamedAccounts, deployments, ethers } = require("hardhat")

const { assert } = require('chai')

describe('TransactionFeeTest', async function () {
    const multiplier = 10 ** 18

    let deployer, user1, user2
    let BLBAddr
    let BLBToken

    before(async function () {
        console.log(getNamedAccounts);
        let accounts =  await getNamedAccounts()
        deployer = accounts.deployer
        user1 = accounts.user1
        user2 = accounts.user2

        BLBAddr = await deployBLBToken()
        BLBToken = await ethers.getContractAt('BLBToken', BLBAddr)
    }) 

    it('fee details should be zero', async () => {
        assert.equal(
            await BLBToken.transactionFee(100),
            0
        )
    })

    it('should set transaction fee', async () => {
        await expect(
            BLBToken.setTransactionFee(0, 1*multiplier.toString(), user1).
            to.be.revertedWith("TransactionFee: Up to 5% transactionFee can be set")
        )
    })

})
