// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./Administration.sol";

/**
 * @title control BLB transfers.
 * @notice users may have access to transfer their whole BLB balance or only a 
 * certain fraction every period(it depends on periodFraction).
 * @notice some specific addresses may have restricted access to transfer.
 * @notice owner of the contract can restrict every desired address and also 
 * determine the a spend limit for all users.
 */
abstract contract TransferControl is ERC20, Administration {
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

    /**
     * @notice set spend limit for period transfers.
     * @notice there is no transfer limit if fraction is 10**6.
     *
     * @param fraction the numerator of transfer limit rate which denominator
     * is 10**6.
     *
     * @notice require:
     *  - only owner of contract can call this function.
     *  - maximum fraction can be 10**6 (equal to 100%).
     */
    function setPeriodTransferFraction(uint256 fraction) 
        public 
        onlyRole(TRANSFER_LIMIT_SETTER) 
    {
        require(fraction <= 10 ** 6, "maximum fraction is 10**6 (equal to 100%)");
        periodFraction = fraction;
    }

    /**
     * @notice restrict an address 
     * @notice the address `addr` will be only able to spend as much as `amount`.
     *
     * @param addr the restricted address.
     * @param amount restricted spendable amount.
     *
     * @notice require:
     *  - only RESTRICTOR_ROLE address can call this function.
     */
    function restrict(address addr, uint256 amount) public onlyRole(RESTRICTOR_ROLE) {
        restrictedAddresses.set(addr, amount);
    }

    /**
     * @notice destrict an address 
     * @notice the address `addr` will be free to spend their BLB like regular
     * addresses.
     *
     * @param addr the address that is going to be destricted.
     *
     * @notice require:
     *  - only RESTRICTOR_ROLE address can call this function.
     */
    function destrict(address addr) public onlyRole(RESTRICTOR_ROLE) {
        restrictedAddresses.remove(addr);
    }

    /**
     * @return boolean true if the address is restricted.
     *
     * @param addr the address that is going to be checked.
     */
    function isRestricted(address addr) public view returns(bool) {
        return restrictedAddresses.contains(addr);
    }

    /**
     * @return amount that the address can spend.
     * 
     * @dev if the address restricted, the amount equals remaining spendable amount for the 
     * address. else if there is a spend limit active for the contract, the amount equals 
     * the address's remaining period spendable amount. else the amount equals balance of the
     * address.
     * 
     * @param addr the address that is being checked.
     */
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
        virtual
        override
    {
        if(!hasRole(MINTER_ROLE, _msgSender())) {
            _spend(from, amount);
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}