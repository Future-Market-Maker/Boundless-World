// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


/**
 * @title deduct transaction fee of every token transfer and send to a third address.
 */
abstract contract TransactionFee is ERC20, AccessControl {

    bytes32 public constant FEE_SETTER = keccak256("FEE_SETTER");

    uint256 feeFraction; // nomerator of transaction fee which denuminator is 1,000,000
    uint256 feeAmount;   // independent transaction fee for every token transfer
    address feeReceiver; // address of the fee receiver

    /**
     * @notice set amount or fraction and receiver of BLB transaction fees in one call.
     *
     * @notice requirement:
     *  - only owner of the contract can call this function.
     *  - one of feeAmount and feeFraction must be zero.
     *  - fee frction can be maximum of 50,000 which equals 5% of the transactions
     *  - if fee fraction is not zero, fee receiver cannot be zero address.
     */
    function setTransactionFee(
        uint256 _feeAmount,
        uint256 _feeFraction, 
        address _feeReceiver
    ) public onlyRole(FEE_SETTER) {
        require(
            _feeFraction == 0 || _feeAmount == 0,
            "cannot have feeAmount and feeFraction at the same time"
        );
        require(_feeFraction <= 5 * 10 ** 4, "you can set up to 5% transactionFee");
        if(feeFraction > 0 || _feeAmount > 0){
            require(_feeReceiver != address(0), "feeReceiver cannot be zero address");
        }
        feeAmount = _feeAmount;
        feeFraction = _feeFraction;
        feeReceiver = _feeReceiver;
    }

    /**
     * @return uint256 transaction fee corresponding to the transferring amount.
     * @notice if there is a fee amount, transaction fee is independent of the transfer amount.
     */
    function transactionFee(uint256 transferingAmount) public view returns(uint256) {
        return feeAmount > 0 ?
            feeAmount :
            transferingAmount * feeFraction / 10 ** 6;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override
    {
        if(feeFraction > 0 || feeAmount > 0) {
            uint256 _transactionFee = transactionFee(amount);
            _pureTransfer(from, feeReceiver, _transactionFee);
            amount -= _transactionFee;
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}