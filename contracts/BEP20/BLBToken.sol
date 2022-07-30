// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./TransferControl.sol";
import "./TransactionFee.sol";

contract BLBToken is 
    ERC20, 
    ERC20Capped, 
    ERC20Burnable, 
    ERC20Permit, 
    AccessControl,
    TransferControl,
    TransactionFee
{

    constructor() 
        ERC20("Boundless World", "BLB") 
        ERC20Capped((3.69 * 10 ** 9) * 10 ** decimals())
        ERC20Permit("Boundless World") 
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(FEE_SETTER, msg.sender);
        _grantRole(TRANSFER_LIMIT_SETTER, msg.sender);
        _grantRole(RESTRICTOR_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }


    // The following functions are overrides required by Solidity.

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, TransferControl, TransactionFee)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}