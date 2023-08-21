// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PancakeSwapper.sol";

contract BLBSwap is Ownable, PancakeSwapper {

    constructor(
        uint256 _BLBsPerUSD
    ) {
        setBLBsPerUSD(_BLBsPerUSD); 
    }

    event Swap(
        address indexed userAddr,
        string indexed tokenIn,
        string indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut 
    );

    function purchaseBLB(
        uint256 amountBUSD
    ) external payable returns(uint256 amountBLB) {

        address purchaser = msg.sender;
        uint256 amountBNB = msg.value;

        if(onPancake) {
            amountBLB = _purchaseBLB(purchaser, amountBUSD, amountBNB);
        } else {
            if(amountBUSD == 0) {
                amountBLB = BLBsForBNB(amountBNB);
                require(blbBalance() >= amountBLB, "insufficient BLB to pay");
                IERC20(BLB).transfer(purchaser, amountBLB); 
                emit Swap(purchaser, "BNB", "BLB", amountBNB, amountBLB);
            } else {
                require(amountBNB == 0, "not allowed to purchase in BUSD and BNB in sameTime");
                amountBLB = BLBsForUSD(amountBUSD);
                require(blbBalance() >= amountBLB, "insufficient BLB to pay");
                TransferHelper.safeTransferFrom(BUSD, purchaser, address(this), amountBUSD);
                TransferHelper.safeTransferFrom(BLB, address(this), purchaser, amountBLB);
                emit Swap(purchaser, "BUSD", "BLB", amountBUSD, amountBLB);
            }
        }
    }

    function sellBLB(
        uint256 amountBLB,
        bool toBUSD
    ) public returns(uint256 amountOut) {

        address seller = msg.sender;
        TransferHelper.safeTransferFrom(BLB, seller, address(this), amountBLB);

        if(onPancake) {
            _sellBLB(seller, amountBLB, toBUSD);
        } else {
            if(toBUSD) {
                amountOut = USDsForBLB(amountBLB);
                require(busdBalance() >= amountOut, "insufficient BUSD to pay");
                IERC20(BUSD).transfer(seller, amountOut);
                emit Swap(seller, "BLB", "BUSD", amountBLB, amountOut);
            } else {
                amountOut = BNBsForBLB(amountBLB);
                require(bnbBalance() >= amountOut, "insufficient BNB to pay");
                payable(seller).transfer(amountOut);
                emit Swap(seller, "BLB", "BNB", amountBLB, amountOut);
            }
        }
    }

    function BLBsForUSD(uint256 amountBUSD) public view returns(uint256) {
        if(onPancake) {
            return _BLBsForUSD(amountBUSD);
        } else {
            return BLBsPerUSD * amountBUSD / 10 ** 18;
        }
    }

    function BLBsForBNB(uint256 amountBNB) public view returns(uint256) {
        if(onPancake) {
            return _BLBsForBNB(amountBNB);
        } else {
            return BLBsForUSD(amountBNB * BNB_BUSD() / 10 ** 18);
        }
    }

    function USDsForBLB(uint256 amountBLB) public view returns(uint256) {
        if(onPancake) {
            return _USDsForBLB(amountBLB);
        } else {
            return amountBLB * 10 ** 18 / BLBsPerUSD;
        }
    }

    function BNBsForBLB(uint256 amountBLB) public view returns(uint256) {
        if(onPancake) {
            return _BNBsForBLB(amountBLB);
        } else {
            return USDsForBLB(amountBLB) * BUSD_BNB() / 10 ** 18;
        }
    }

// administration ---------------------------------------------------------------------------------------

    uint256 public BLBsPerUSD;  //how much BLBs is earned for 1 USD.
    function setBLBsPerUSD(
        uint256 BLBsAmount
    ) public onlyOwner {
        BLBsPerUSD = BLBsAmount;
    }

    function blbBalance() public view returns(uint256) {
        return IERC20(BLB).balanceOf(address(this));
    }
    function busdBalance() public view returns(uint256) {
        return IERC20(BUSD).balanceOf(address(this));
    }
    function bnbBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function withdrawBLB(uint256 amount) public onlyOwner {
        IERC20(BLB).transfer(owner(), amount);
    }
    function withdrawBUSD(uint256 amount) public onlyOwner {
        IERC20(BUSD).transfer(owner(), amount);
    }
    function withdrawBNB(uint256 amount) public onlyOwner {
        payable(owner()).transfer(amount);
    }

    bool public onPancake;
    function setOnPancake() public onlyOwner {
        onPancake = onPancake ? false : true;
    }
}