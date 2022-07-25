// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title deduct transaction fee of every token transfer and send to a third address.
 */
abstract contract TransactionFee is ERC20, Ownable {

    uint256 feeFraction; //denuminator is 1,000,000
    address feeReceiver;

    /**
     * @notice set fraction and receiver of BLB transaction fees in one call.
     *
     * @notice requirement:
     *  - only owner of the contract can call this function.
     *  - fee frction can be maximum of 50,000 which equals 5% of the transactions
     *  - if fee fraction is not zero, fee receiver cannot be zero address.
     */
    function setTransactionFee(
        uint256 _feeFraction, 
        address _feeReceiver
    ) public onlyOwner {
        require(_feeFraction <= 5 * 10 ** 4, "your can set up to 5% transactionFee");
        if(feeFraction > 0){
            require(_feeReceiver != address(0), "feeReceiver cannot be zero address");
        }
        feeFraction = _feeFraction;
        feeReceiver = _feeReceiver;
    }

    /**
     * @return uint256 transaction fee corresponding to the transferring amount.
     */
    function transactionFee(uint256 transferingAmount) public view returns(uint256) {
        return transferingAmount * feeFraction / 10 ** 6;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override
    {
        if(feeFraction > 0) {
            uint256 _transactionFee = transactionFee(amount);
            _pureTransfer(from, feeReceiver, _transactionFee);
            amount -= _transactionFee;
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}