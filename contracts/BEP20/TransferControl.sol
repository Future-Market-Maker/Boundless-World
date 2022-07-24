// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

abstract contract TransferControl is ERC20, Ownable {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    EnumerableMap.AddressToUintMap restrictedAddresses;

    struct Period {
        uint256 spent;
        uint256 nonce;
    }

    mapping(address => Period) checkpoints;

    uint256 periodFraction;
    uint256 immutable startTime;
    uint256 immutable periodTime;

    constructor() {
        startTime = block.timestamp;
        periodTime = 30 days;
    }

    function setperiodTransferFraction(uint256 fraction) public onlyOwner {
        require(fraction <= 10 ** 6, "maximum fraction is 10**6 (equal to 100%)");
        periodFraction = fraction;
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
            if(periodFraction == 10 ** 6){
                return balanceOf(addr);
            } else {
                uint256 periodAmount = balanceOf(addr) * periodFraction / 10 ** 6;
                return checkpoints[addr].nonce != (block.timestamp - startTime) / periodTime ?
                    periodAmount :
                    periodAmount - checkpoints[addr].spent;
            }
        }
    }

    function _spend(address addr, uint256 amount) internal {
        if(isRestricted(addr)) {
            uint256 spendableAmount = restrictedAddresses.get(addr);
            require(amount <= spendableAmount, "amount exceeds spend limit");
            restrictedAddresses.set(addr, spendableAmount - amount);
        } else {
            if(periodFraction != 10 ** 6) {
                uint256 periodAmount = balanceOf(addr) * periodFraction / 10 ** 6;
                uint256 currentNonce = (block.timestamp - startTime) / periodTime;
                if(checkpoints[addr].nonce == currentNonce) {
                    amount += checkpoints[addr].spent;
                }
                require(amount <= periodAmount, "amount exceeds period spend limit");
                checkpoints[addr] = Period(amount, currentNonce);
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