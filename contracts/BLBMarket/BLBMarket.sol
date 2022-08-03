// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

contract BLBMarket is Ownable {

    IERC20 public BLB;
    IERC20 public BUSD;
    IERC20 public USDT;

    //aggregator on rinkeby
    AggregatorInterface constant AGGREGATOR_DAI_ETH_18 = AggregatorInterface(0x74825DbC8BF76CC4e9494d0ecB210f676Efa001D);

    constructor() {
        BLB = IERC20(address(0));
        BUSD = IERC20(address(0));
        USDT = IERC20(address(0));
    }

    /**
    * @notice set ticket price in usd with 10 digits of decimals.
    * @notice only owner of the contract can set ticket price in USD.
    */
    uint256 public priceInUSD_10;
    function set_priceInUSD_10(uint256 _priceInUSD_10) public onlyOwner {
        priceInUSD_10 = _priceInUSD_10;
    }

    function priceInBNB_18() public view returns(uint256) {
        return uint256(AGGREGATOR_DAI_ETH_18.latestAnswer())
            * priceInUSD_10
            / 10 ** 10;
    }


    function buyInBNB(uint256 amount) public payable {
        require(msg.value >= amount * priceInBNB_18() /100*98, "insufficient fee");
        require(BLB.balanceOf(address(this)) >= amount, "insufficient BLB in the contract");
        BLB.transfer(msg.sender, amount);
    }

    function buyInBUSD(uint256 amount) public {
        require(BLB.balanceOf(address(this)) >= amount, "insufficient BLB in the contract");
        BUSD.transferFrom(msg.sender, address(this), priceInUSD_10 * amount / 10**10); 
        BLB.transfer(msg.sender, amount);       
    }

    function buyInUSDT(uint256 amount) public payable {
        require(BLB.balanceOf(address(this)) >= amount, "insufficient BLB in the contract");
        BUSD.transferFrom(msg.sender, address(this), priceInUSD_10 * amount / 10**10);        
        BLB.transfer(msg.sender, amount);       
    }

    function withdraw(address tokenAddr, uint256 amount) public onlyOwner {
        IERC20(tokenAddr).transfer(msg.sender, amount);
    }
}