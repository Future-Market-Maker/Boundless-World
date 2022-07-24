// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

abstract contract TransferControl is ERC20, Ownable {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    EnumerableMap.AddressToUintMap restrictedAddresses;

    struct Checkpoint {
        uint256 spentAmount;
        uint256 nonce;
    }

    mapping(address => Checkpoint) checkpoints;

    uint256 monthlyTransferFraction;
    uint256 startTime;

    constructor() {
        startTime = block.timestamp;
    }

    // restricted addresses
    function restrict(address addr, uint256 amount) public onlyOwner {
        restrictedAddresses.set(addr, amount);
    }
    function destrict(address addr) public onlyOwner {
        restrictedAddresses.remove(addr);
    }


    function canSpend(address addr) public view returns(uint256) {
        return isRestricted(addr) ?
            restrictedAddresses.get(addr) :
            balanceOf(addr) * monthlyTransferFraction / 10 ** 6 - 
                checkpoints[addr].spentAmount;
    }

    function isRestricted(address addr) public view returns(bool) {
        return restrictedAddresses.contains(addr);
    }

    function _spend(address addr, uint256 amount) internal {
        if(isRestricted(addr)) {
            uint256 spendableAmount = restrictedAddresses.get(addr);
            require(amount <= spendableAmount, "amount exceeds spend limit");
            restrictedAddresses.set(addr, spendableAmount - amount);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }


}