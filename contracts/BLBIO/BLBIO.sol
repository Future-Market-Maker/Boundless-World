// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import "./BLBIOAdministration.sol";


contract BLBIO is BLBIOAdministration {

    AggregatorInterface immutable AGGREGATOR_BUSD_BNB;

    IERC20 public BLB;
    IERC20 public BUSD;

    bool public soldOut;
    function setSoldOut() public onlyOwner {
        soldOut = soldOut ? false : true;
    }


    constructor() {
        BLB = IERC20(0x134341a04B11B1FD697Fc57Eab7D96bDbcdEa414); 
        BUSD = IERC20(0xCd57b180aeA8B61C7b273785748988A3A8eAb9c2);
        AGGREGATOR_BUSD_BNB = AggregatorInterface(0x0630521aC362bc7A19a4eE44b57cE72Ea34AD01c);

        setPriceInUSD(
            0.30 * 10 ** 18, //equals 0.3 USD
            0.28 * 10 ** 18  //equals 0.28 USD
        ); 
        setRetailLimit(
            500 * 10 ** 18 //equals 500 blb
        ); 
    }

    event BuyInBNB(
        address indexed buyer,
        uint256 indexed amountBLB, 
        uint256 indexed amountBNB
    );
    event BuyInBUSD(
        address indexed buyer,
        uint256 indexed amountBLB, 
        uint256 indexed amountBUSD
    );
    event Claim(
        address indexed claimant,
        uint256 indexed amountBLB
    );

    function priceInUSD(uint256 amount) public view returns(uint256) {
        require(!soldOut, "BLBIO: sold out!");
        return amount > retailLimit ? privatePriceInUSD : publicPriceInUSD
            * amount / 10 ** 18;
    }


    function priceInBNB(uint256 amount) public view returns(uint256) {
        require(!soldOut, "BLBIO: sold out!");
        return uint256(AGGREGATOR_BUSD_BNB.latestAnswer())
            * priceInUSD(amount) / 10 ** 18;
    }


    function buyInBNB(uint256 amount) public payable {
        address buyer = msg.sender;
        require(msg.value >= priceInBNB(amount) * 98/100, "insufficient fee");
        userClaims[buyer].initialAmount += amount;       
        emit BuyInBNB(buyer, amount, msg.value);
    }

    function buyInBUSD(uint256 amount) public {
        address buyer = msg.sender;
        require(BLB.balanceOf(address(this)) >= amount, "insufficient BLB in the contract");
        uint256 payableBUSD = priceInUSD(amount);
        BUSD.transferFrom(buyer, address(this), payableBUSD); 
        userClaims[buyer].initialAmount += amount;       
        emit BuyInBUSD(buyer, amount, payableBUSD);
    }

    uint256 public claimableFraction;
    function increaseClaimableFraction(uint256 fraction) public onlyOwner {
        claimableFraction += fraction;

        require(claimableFraction <= 1000000, "BLBIO: fraction exceeds 10^6");
    }

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
            return uc.initialAmount * claimableFraction/1000000  - uc.claimedAmount;
        }
    }

    function claim() public {
        address claimant = msg.sender; 
        UserClaim storage uc = userClaims[claimant];
        uint256 _claimable = claimable(claimant);

        require(_claimable != 0, "BLBIO: there is no BLB to claim");
        require(BLB.balanceOf(address(this)) >= _claimable, "insufficient BLB in the contract");

        uc.claimedAmount += _claimable;

        BLB.transfer(claimant, _claimable); 

        emit Claim(claimant, _claimable);      
    }
}