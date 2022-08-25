// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Administration.sol";

/**
 * @title deduct transaction fee of every token transfer and send to a third address.
 */
abstract contract TransactionFee is ERC20, Administration {


    uint256 feeFraction; // numerator of transaction fee which denominator is 1,000,000
    uint256 feeAmount;   // independent transaction fee for every token transfer
    address feeReceiver; // address of the fee receiver

    /**
     * @notice set amount or fraction and receiver of BLB transaction fees.
     *
     * @notice if transaction receiver is zero address, the transaction fee will be burned.
     *
     * @notice requirement:
     *  - only owner of the contract can call this function.
     *  - one of feeAmount or feeFraction must be zero.
     *  - fee frction can be maximum of 50,000 which equals 5% of the transactions
     */
    function setTransactionFee(
        uint256 _feeAmount,
        uint256 _feeFraction, 
        address _feeReceiver
    ) public onlyRole(FEE_SETTER) {
        require(
            _feeFraction == 0 || _feeAmount == 0,
            "TransactionFee: Cannot set feeAmount and feeFraction at the same time"
        );
        require(
            _feeFraction <= 5 * 10 ** 4, 
            "TransactionFee: Up to 5% transactionFee can be set"
        );
        feeAmount = _feeAmount;
        feeFraction = _feeFraction;
        feeReceiver = _feeReceiver;
    }

    /**
     * @return fee transaction fee corresponding to the transferring amount.
     * @notice if there is a fee amount, transaction fee is not proportional to the transfer amount.
     */
    function transactionFee(uint256 transferingAmount) public view returns(uint256 fee) {
        if(feeAmount > 0)
            fee = feeAmount;
        else if( feeFraction > 0)
            fee = transferingAmount * feeFraction / 10 ** 6;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override
    {
        address caller = _msgSender();
        if(!hasRole(MINTER_ROLE, caller)) {
            if(feeFraction > 0 || feeAmount > 0) {
                uint256 _transactionFee = transactionFee(amount);
                _pureTransfer(caller, feeReceiver, _transactionFee);
            }
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}