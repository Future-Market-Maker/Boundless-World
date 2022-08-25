// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "./TransferControl.sol";
import "./TransactionFee.sol";

/**
 * @title Boundless World (BLB) Token
 */
contract BLBToken is 
    ERC20, 
    ERC20Capped, 
    ERC20Burnable, 
    ERC20Permit, 
    TransactionFee,
    TransferControl
{

    constructor() 
        ERC20("Boundless World", "BLB") 
        ERC20Capped((3.69 * 10 ** 9) * 10 ** decimals())
        ERC20Permit("Boundless World") 
    {
        // address initialAdmin = 0x31FBc230BC6b8cE2eE229eCfbACCc364Da3eD7fC;
        address initialAdmin = msg.sender;

        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(MINTER_ROLE, initialAdmin);
        _grantRole(FEE_SETTER, initialAdmin);
        _grantRole(TRANSFER_LIMIT_SETTER, initialAdmin);
        _grantRole(RESTRICTOR_ROLE, initialAdmin);
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