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

//-------------------------------------------------------------------------------
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

//-------------------------------------------------------------------------------
    it('should mint BLB in BLBIO', async () => {
        await BLBAddr.mint(BLBIOAddr.address, (100 * 10**18).toString())

        assert.equal(
            await BLBIOAddr.blbBalance(),
            100 * 10**18
        )
    })

//-------------------------------------------------------------------------------
    it('should return price in USD', async () => {
        assert.equal(
            await BLBIOAddr.privatePriceInUSD(),
            28 * 10**16
        )
    })

//-------------------------------------------------------------------------------
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

//-------------------------------------------------------------------------------
    it('should gift correctly', async () => {
        await BLBIOAddr.giftBLB(user1.address, (2 * 10**18).toString(), true)

        assert.equal(
            await BLBIOAddr.TotalClaimable(),
            2 * 10**18
        )
        assert.equal(
            await BLBIOAddr.totalClaimable(user1.address),
            2 * 10**18
        )
        assert.equal(
            await BLBIOAddr.claimable(user1.address),
            2 * 10**18
        )
    })


//-------------------------------------------------------------------------------
    it('should mint BUSD in buyer address', async () => {
        await BUSDAddr.mint(user2.address, (1 * 10**18).toString())
    })

    it('should buy in BUSD', async () => {
        await BUSDAddr.connect(user2).approve(BLBIOAddr.address, (6 * 10**17).toString())
        await BLBIOAddr.connect(user2).buyInBUSD((2 * 10**18).toString())

        assert.equal(
            await BLBIOAddr.busdBalance(),
            6 * 10**17
        )
        assert.equal(
            await BLBIOAddr.TotalClaimable(),
            4 * 10**18
        )
        assert.equal(
            await BLBIOAddr.totalClaimable(user2.address),
            2 * 10**18
        )
        assert.equal(
            await BLBIOAddr.claimable(user2.address),
            0
        )
    })

//-------------------------------------------------------------------------------
    it('should not claim if claimable fraction is zero', async () => {

        assert.equal(
            await BLBIOAddr.claimableFraction(),
            0
        )

        await expect(
            BLBIOAddr.connect(user2).claim()
        ).to.be.revertedWith("BLBIO: there is no BLB to claim")
    })

    it('owner should set new fraction', async () => {

        await BLBIOAddr.increaseClaimableFraction(500000)

        assert.equal(
            await BLBIOAddr.totalClaimable(user2.address),
            2 * 10**18
        )
        assert.equal(
            await BLBIOAddr.claimable(user2.address),
            1 * 10**18
        )
    })   
    
    it('should claim if claimable fraction is not zero', async () => {

        assert.equal(
            await BLBIOAddr.claimableFraction(),
            500000
        )

        await BLBIOAddr.connect(user2).claim()

        assert.equal(
            await BLBIOAddr.totalClaimable(user2.address),
            1 * 10**18
        )
        assert.equal(
            await BLBIOAddr.claimable(user2.address),
            0
        )
    })

    it('new claim fraction should be added to latest', async () => {

        await BLBIOAddr.increaseClaimableFraction(250000)

        assert.equal(
            await BLBIOAddr.claimableFraction(),
            750000
        )

        await BLBIOAddr.connect(user2).claim()

        assert.equal(
            await BLBIOAddr.totalClaimable(user2.address),
            5 * 10**17
        )
        assert.equal(
            await BLBIOAddr.claimable(user2.address),
            0
        )
    })

})
