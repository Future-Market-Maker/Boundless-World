// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BLBIOAdministration is Ownable {

    uint256 public retailLimit;

    event SetRetailLimit(uint256 indexed _retailLimit);

    function setRetailLimit(uint256 _retailLimit) public onlyOwner {
        retailLimit = _retailLimit;
        emit SetRetailLimit(_retailLimit);
    }

//------------------------------------------------------------------------------------

    struct UserClaim{
        uint256 total;
        uint256 claimed;
        bool freeToClaim;
    }
    mapping(address => UserClaim) userClaims;

    function giftBLB(
        address claimant, 
        uint256 amount, 
        bool freeToClaim
    ) public onlyOwner {
        userClaims[claimant].total += amount; 
        userClaims[claimant].freeToClaim = freeToClaim; 

    }

//------------------------------------------------------------------------------------

    uint256 public claimableFraction;
    function increaseClaimableFraction(uint256 fraction) public onlyOwner {
        claimableFraction += fraction;

        require(claimableFraction <= 1000000, "BLBIO: fraction exceeds 10^6");
    }
//------------------------------------------------------------------------------------

    uint256 public privatePriceInUSD;
    uint256 public publicPriceInUSD;

    event SetPriceInUSD(uint256 indexed publicPrice, uint256 indexed privatePrice);

    function setPriceInUSD(
        uint256 _publicPrice,
        uint256 _privatePrice
    ) public onlyOwner {
        publicPriceInUSD = _publicPrice;
        privatePriceInUSD = _privatePrice;
        emit SetPriceInUSD(_publicPrice, _privatePrice);
    }


//------------------------------------------------------------------------------------

    event Withdraw(address indexed tokenAddr, uint256 indexed amount);

    function withdrawERC20(address tokenAddr, uint256 amount) public onlyOwner {
        IERC20(tokenAddr).transfer(msg.sender, amount);
        emit Withdraw(tokenAddr, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
        emit Withdraw(address(0), amount);
    }
}