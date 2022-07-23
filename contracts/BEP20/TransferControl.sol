// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract TransferControl is ERC20, Ownable {

    struct Restriction {
        uint256 monthlyAmount;
        uint256 spentAmount;
        uint256 nonce;
    }

    mapping(address => Restriction) restrictedAddresses;

    uint256 monthlyTransferFraction;
    uint256 startTime;

    constructor() {
        startTime = block.timestamp;
    }

    function restrict(address addr, uint256 monthlyTransfers) public onlyOwner {
        restrictedAddresses[addr].monthlyAmount = monthlyTransfers;
    }

    function destrict(address addr) public onlyOwner {
        delete restrictedAddresses[addr];
    }

    function canSpend(address addr) public view returns(uint256 ) {
        return restrictedAddresses[addr].monthlyAmount != 0 ?
            restrictedAddresses[addr].monthlyAmount - restrictedAddresses[addr].spentAmount :
            balanceOf(addr) * monthlyTransferFraction / 10 ** 6;
    }

    function isRestricted(address addr) public view returns(bool) {
        return restrictedAddresses[addr].monthlyAmount != 0;
    }

    function _spend(address restrictedAddr, uint256 amount) internal {

    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }


}