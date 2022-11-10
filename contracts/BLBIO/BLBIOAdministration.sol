// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BLBIOAdministration is Ownable {


//------------------------------------------------------------------------------------

    struct UserClaim {
        uint256 total;
        uint256 claimed;
        bool freeToClaim;
    }
    mapping(address => UserClaim) userClaims;

    function giftBLB(
        address addr, 
        uint256 amount, 
        bool freeToClaim
    ) public onlyOwner {
        userClaims[addr].total += amount; 
        userClaims[addr].freeToClaim = freeToClaim; 
    }

//------------------------------------------------------------------------------------

    uint256 public claimableFraction;
    function increaseClaimableFraction(uint256 fraction) public onlyOwner {
        claimableFraction += fraction;

        require(claimableFraction <= 1000000, "BLBIO: fraction exceeds 10^6");
    }
//------------------------------------------------------------------------------------

    uint256 public retailLimit;
    uint256 public privatePriceInUSD;
    uint256 public publicPriceInUSD;


    event SetPriceInUSD(uint256 indexed publicPrice, uint256 indexed privatePrice);
    event SetRetailLimit(uint256 indexed _retailLimit);


    function setRetailLimit(uint256 _retailLimit) public onlyOwner {
        retailLimit = _retailLimit;
        emit SetRetailLimit(_retailLimit);
    }

    function setPriceInUSD(
        uint256 _publicPrice,
        uint256 _privatePrice
    ) public onlyOwner {
        publicPriceInUSD = _publicPrice;
        privatePriceInUSD = _privatePrice;
        emit SetPriceInUSD(_publicPrice, _privatePrice);
    }

//------------------------------------------------------------------------------------

    IERC20 public BLB;
    IERC20 public BUSD;

    uint256 public TotalClaimable;

    function blbBalance() public view returns(uint256) {
        return BLB.balanceOf(address(this));
    }

    function busdBalance() public view returns(uint256) {
        return BUSD.balanceOf(address(this));
    }

    function bnbBalance() public view returns(uint256) {
        return address(this).balance;
    }

    event Withdraw(string indexed tokenName, uint256 amount);

    function withdrawBLB(uint256 amount) public onlyOwner {
        BLB.transfer(owner(), amount);
        emit Withdraw("BLB", amount);
    }

    function withdrawBUSD(uint256 amount) public onlyOwner {
        BUSD.transfer(owner(), amount);
        emit Withdraw("BUSD", amount);
    }

    function withdrawBNB(uint256 amount) public onlyOwner {
        payable(owner()).transfer(amount);
        emit Withdraw("BNB", amount);
    }
}