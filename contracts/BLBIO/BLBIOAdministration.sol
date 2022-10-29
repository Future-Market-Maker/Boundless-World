// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BLBIOAdministration is Ownable {

    /**
     * @return amount of the token in which the price decreases from retail to bulk.
     *
     * @notice multiplied by 10^18.
     */
    uint256 public retailLimit;

    /**
     * @dev emits when the owner sets a new retail limit.
     */
    event SetRetailLimit(uint256 indexed _retailLimit);

    /**
     * @dev set retail limit;
     *
     * @notice multiplied by 10^18.
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *
     * @notice emits a SetPriceInUSD event
     */
    function setRetailLimit(uint256 _retailLimit) public onlyOwner {
        retailLimit = _retailLimit;
        emit SetRetailLimit(_retailLimit);
    }


//------------------------------------------------------------------------------------
    /**
     * @return price of the token in USD in bulk purchase.
     *
     * @notice multiplied by 10^18.
     */
    uint256 public privatePriceInUSD;

    /**
     * @return price of the token in USD in retail purchase.
     *
     * @notice multiplied by 10^18.
     */
    uint256 public publicPriceInUSD;


    /**
     * @dev emits when the owner sets new prices for private and public blb sale (in USD).
     */
    event SetPriceInUSD(uint256 indexed publicPrice, uint256 indexed privatePrice);

    /**
     * @dev set ticket price in USD for public sale and private sale;
     *
     * @notice multiplied by 10^18.
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *
     * @notice emits a SetPriceInUSD event
     */
    function setPriceInUSD(
        uint256 _publicPrice,
        uint256 _privatePrice
    ) public onlyOwner {
        publicPriceInUSD = _publicPrice;
        privatePriceInUSD = _privatePrice;
        emit SetPriceInUSD(_publicPrice, _privatePrice);
    }


//------------------------------------------------------------------------------------
    /**
     * @dev emits when the owner withdraws any amount of BNB or ERC20 token.
     *  
     * @notice if the withdrawing token is BNB, tokenAddr equals address zero.
     */
    event Withdraw(address indexed tokenAddr, uint256 indexed amount);

    /**
     * @dev withdraw ERC20 tokens from the contract.
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *
     * @notice emits a Withdraw event
     */
    function withdrawERC20(address tokenAddr, uint256 amount) public onlyOwner {
        IERC20(tokenAddr).transfer(msg.sender, amount);
        emit Withdraw(tokenAddr, amount);
    }

    /**
     * @dev withdraw BNB from the contract.
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *
     * @notice emits a Withdraw event(address zero as the BNB token)
     */
    function withdraw(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
        emit Withdraw(address(0), amount);
    }
}