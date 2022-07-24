// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

abstract contract TransferControl is ERC20, Ownable {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    EnumerableMap.AddressToUintMap restrictedAddresses;

    struct Checkpoint {
        uint256 lastSpend;
        uint256 nonce;
    }

    mapping(address => Checkpoint) checkpoints;

    uint256 monthlyFraction;
    uint256 immutable startTime;
    uint256 immutable period;

    constructor() {
        startTime = block.timestamp;
        period = 30 days;
    }

    function setMonthlyTransferFraction(uint256 fraction) public onlyOwner {
        require(fraction <= 10 ** 6, "maximum fraction is 10**6 (equal to 100%)");
        monthlyFraction = fraction;
    }

    // restricted addresses
    function restrict(address addr, uint256 amount) public onlyOwner {
        restrictedAddresses.set(addr, amount);
    }
    function destrict(address addr) public onlyOwner {
        restrictedAddresses.remove(addr);
    }

    function isRestricted(address addr) public view returns(bool) {
        return restrictedAddresses.contains(addr);
    }

    function canSpend(address addr) public view returns(uint256 amount) {
        if (isRestricted(addr)){
            return restrictedAddresses.get(addr);
        } else {
            if(monthlyFraction == 10 ** 6){
                return balanceOf(addr);
            } else {
                uint256 monthlyAmount = balanceOf(addr) * monthlyFraction / 10 ** 6;
                return checkpoints[addr].nonce != (block.timestamp - startTime) / period ?
                    monthlyAmount :
                    monthlyAmount - checkpoints[addr].lastSpend;
            }
        }
    }

    function _spend(address addr, uint256 amount) internal {
        uint256 spendableAmount;
        if(isRestricted(addr)) {
            spendableAmount = restrictedAddresses.get(addr);
            require(amount <= spendableAmount, "amount exceeds spend limit");
            restrictedAddresses.set(addr, spendableAmount - amount);
        } else {
            if(monthlyFraction != 10 ** 6) {
                uint256 monthlyAmount = balanceOf(addr) * monthlyFraction / 10 ** 6;
                uint256 currentNonce = (block.timestamp - startTime) / period;
                if(checkpoints[addr].nonce == currentNonce) {
                    spendableAmount = monthlyAmount - checkpoints[addr].lastSpend;
                } else {
                    spendableAmount = monthlyAmount;
                }
                require(spendableAmount <= amount, "amount exceeds spend limit");
                checkpoints[addr] = Checkpoint(amount, currentNonce);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        _spend(from, amount);
        super._beforeTokenTransfer(from, to, amount);
    }
}