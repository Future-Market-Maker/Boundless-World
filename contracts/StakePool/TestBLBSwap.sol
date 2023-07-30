// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TestBLBSwap {
    function BLBsForUSD(uint256 amountBUSD) external pure returns(uint256){
        return amountBUSD * 10;
    }
    function BLBsForBNB(uint256 amountBNB) external pure returns(uint256) {
        return amountBNB * 2000;
    }
}