// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import "./BLBIOAdministration.sol";


/**
 * @title BLB Initial Offering
 *
 * @dev BLB Token is offered in BNB and BUSD(USDT).
 * @dev the prices are set in USD and calculated to corresponding BNB in 
 *   every buy transaction via chainlink price feed aggregator.
 * @dev there two sale plan; public sale price for small amounts and private sale
 *  price for large amounts of blb.
 * @dev since solidity does not support floating variables, all prices are
 *   multiplied by 10^18 to embrace decimals.
 */
contract BLBIO is BLBIOAdministration {

    AggregatorInterface immutable AGGREGATOR_BUSD_BNB;

    IERC20 public BLB;
    IERC20 public BUSD;


    constructor() {
        //addresses on bsc testnet
        BLB = IERC20(0x134341a04B11B1FD697Fc57Eab7D96bDbcdEa414); 
        BUSD = IERC20(0xCd57b180aeA8B61C7b273785748988A3A8eAb9c2);
        AGGREGATOR_BUSD_BNB = AggregatorInterface(0x0630521aC362bc7A19a4eE44b57cE72Ea34AD01c);

        // //addresses on bsc mainnet
        // BLB = IERC20(0x3034e7400F7DE5559475a6f0398d26991f965ca3); 
        // BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        // AGGREGATOR_BUSD_BNB = AggregatorInterface(0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941);
        
        setPriceInUSD(
            0.30 * 10 ** 18, //equals 0.3 USD
            0.28 * 10 ** 18  //equals 0.28 USD
        ); 
        setRetailLimit(
            500 * 10 ** 18 //equals 500 blb
        ); 
    }

    event BuyInBNB(uint256 indexed amountBLB, uint256 indexed amountBNB);
    event BuyInBUSD(uint256 indexed amountBLB, uint256 indexed amountBUSD);


    function priceInUSD(uint256 amount) public view returns(uint256) {
        return amount > retailLimit ? privatePriceInUSD : publicPriceInUSD
            * amount / 10 ** 18;
    }


    function priceInBNB(uint256 amount) public view returns(uint256) {
        return uint256(AGGREGATOR_BUSD_BNB.latestAnswer())
            * priceInUSD(amount) / 10 ** 18;
    }


    function buyInBNB(uint256 amount) public payable {
        require(msg.value >= priceInBNB(amount) * 98/100, "insufficient fee");
        require(BLB.balanceOf(address(this)) >= amount, "insufficient BLB in the contract");
        BLB.transfer(msg.sender, amount);
        emit BuyInBNB(amount, msg.value);
    }

    function buyInBUSD(uint256 amount) public {
        require(BLB.balanceOf(address(this)) >= amount, "insufficient BLB in the contract");
        uint256 payableBUSD = priceInUSD(amount);
        BUSD.transferFrom(msg.sender, address(this), payableBUSD); 
        BLB.transfer(msg.sender, amount);       
        emit BuyInBUSD(amount, payableBUSD);
    }

    uint256 fraction;
    
    struct UserClaim{
        uint256 initialAmount;
        uint256 claimedAmount;
        bool freeToClaim;
    }
    mapping(address => UserClaim) userClaims;

    function totalClaimable(address claimant) public view returns(uint256) {
        UserClaim storage uc = userClaims[claimant];
        return uc.initialAmount - uc.claimedAmount;
    }

    function claimable(address claimant) public view returns(uint256) {
        UserClaim storage uc = userClaims[claimant];
        
        if(uc.freeToClaim) {
            return totalClaimable(claimant);
        } else {
            return uc.initialAmount * fraction/1000000  - uc.claimedAmount;
        }
    }

    function claim() public {
        address claimant = msg.sender; 
        UserClaim storage uc = userClaims[claimant];
        uint256 _claimable = claimable(claimant);

        require(_claimable != 0, "BLBIO: there is no BLB to claim");

        uc.claimedAmount += _claimable;

        BLB.transfer(claimant, _claimable);       
    }
}