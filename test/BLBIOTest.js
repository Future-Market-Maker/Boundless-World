/* global describe it before ethers */

const { assert, expect } = require('chai')

describe('TransactionFeeTest', async function () {

    let zero_address
    let deployer, user1, user2
    let BLBAddr
    let BLB
    let BUSDAddr
    let BUSD
    let BLBIOAddr
    let BLBIO

    before(async function () {
        zero_address = "0x0000000000000000000000000000000000000000"
        const accounts = await ethers.getSigners();
        [deployer, user1, user2] = accounts
        
        BLB = await hre.ethers.getContractFactory("BLBToken");
        BLBAddr = await BLB.deploy(deployer.address);
        
        BUSD = await hre.ethers.getContractFactory("ERC20Test");
        BUSDAddr = await BUSD.deploy("BUSD Token", "BUSD");

        BLBIO = await hre.ethers.getContractFactory("BLBIO");
        BLBIOAddr = await BLBIO.deploy(
            BLBAddr.address,
            BUSDAddr.address,
            zero_address
        );
    }) 


    it('should mint BLB in BLBIO', async () => {
        await BLBAddr.mint(BLBIOAddr.address, (100 * 10**18).toString())
    })

    it('should mint BUSD in buyer address', async () => {
        await BUSDAddr.mint(user1.address, (1 * 10**18).toString())
    })

    it('should return price in USD', async () => {
        assert.equal(
            await BLBIOAddr.privatePriceInUSD(),
            28 * 10**16
        )
    })

    it('should return price in USD when not sold out', async () => {
        assert.equal(
            await BLBIOAddr.priceInUSD((2 * 10**18).toString()),
            6 * 10**17
        )

        await BLBIOAddr.setSoldOut()

        await expect(
            BLBIOAddr.priceInUSD((2 * 10**18).toString())
        ).to.be.revertedWith("BLBIO: sold out!")

        await BLBIOAddr.setSoldOut()
    })

    it('should buy in BUSD', async () => {
        await BUSDAddr.connect(user1).approve(BLBIOAddr.address, (6 * 10**17).toString())
        await BLBIOAddr.connect(user1).buyInBUSD((2 * 10**18).toString())

        assert.equal(
            await BUSDAddr.balanceOf(BLBIOAddr.address),
            6 * 10**17
        )
        
    })

})
