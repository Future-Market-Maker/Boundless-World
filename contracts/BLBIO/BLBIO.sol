// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";


/**
 * @title BLB Initial Offering
 *
 * @notice Initial BLB Token Offering.
 */
contract BLBIO is Ownable {

    IERC20 public BLB;
    IERC20 public BUSD;
    IERC20 public USDT;

    uint256 public priceInUSD;

    //aggregator on rinkeby (multiplied by 10^18)
    AggregatorInterface constant AGGREGATOR_DAI_ETH = AggregatorInterface(0x74825DbC8BF76CC4e9494d0ecB210f676Efa001D);

    event BuyInBNB(uint256 indexed amountBLB, uint256 indexed amountBNB);
    event BuyInUSDT(uint256 indexed amountBLB, uint256 indexed amountUSDT);
    event BuyInBUSD(uint256 indexed amountBLB, uint256 indexed amountBUSD);
    event SetPriceInUSD(uint256 indexed newPrice);
    event Withdraw(address indexed tokenAddr, uint256 indexed amount);

    constructor() {
        BLB = IERC20(0x314FbBFC5c9Db19BC8F8981781D326A9bA76508f); //BLB test on rinkeby
        BUSD = IERC20(0x5a47B08A3e5058CF3b68b583851CCf585718AE44);//simple ERC20 on rinkeby
        USDT = IERC20(0x76a90A822b4c797C0BfaED9453445241e5553D00);//simple ERC20 on rinkeby
        setPriceInUSD(10 ** 18); // equals to 1 USD
    }

    /**
     * @return price of the token in BNB corresponding to the USD price.
     *
     * @notice multiplied by 10^18.
     */
    function priceInBNB() public view returns(uint256) {
        return uint256(AGGREGATOR_DAI_ETH.latestAnswer())
            * priceInUSD
            / 10 ** 18;
    }


    /**
     * @dev buy BLB Token paying in BNB.
     *
     * @notice multiplied by 10^18.
     * @notice maximum tolerance 2%.
     *
     * @notice requirement:
     *   - there must be sufficient BLB token in ICO.
     *   - required amount must be paid in BNB.
     *
     * @notice emits a BuyInBNB event
     */
    function buyInBNB(uint256 amount) public payable {
        require(msg.value >= amount * priceInBNB() * 98 / 10**20, "insufficient fee");
        require(BLB.balanceOf(address(this)) >= amount, "insufficient BLB in the contract");
        BLB.transfer(msg.sender, amount);
        emit BuyInBNB(amount, msg.value);
    }

    /**
     * @dev buy BLB Token paying in BUSD.
     *
     * @notice multiplied by 10^18.
     *
     * @notice requirement:
     *   - there must be sufficient BLB token in ICO.
     *   - Buyer must approve the ICO to spend required BUSD.
     *
     * @notice emits a BuyInBUSD event
     */
    function buyInBUSD(uint256 amount) public {
        require(BLB.balanceOf(address(this)) >= amount, "insufficient BLB in the contract");
        uint256 payableBUSD = priceInUSD * amount / 10 ** 18;
        BUSD.transferFrom(msg.sender, address(this), payableBUSD); 
        BLB.transfer(msg.sender, amount);       
        emit BuyInBUSD(amount, payableBUSD);
    }

    /**
     * @dev buy BLB Token paying in BUSD.
     *
     * @notice multiplied by 10^18.
     *
     * @notice requirement:
     *   - there must be sufficient BLB token in ICO.
     *   - Buyer must approve the ICO to spend required USDT.
     *
     * @notice emits a BuyInUSDT event
     */
    function buyInUSDT(uint256 amount) public {
        require(BLB.balanceOf(address(this)) >= amount, "insufficient BLB in the contract");
        uint256 payableUSDT = priceInUSD * amount / 10 ** 18;
        USDT.transferFrom(msg.sender, address(this), payableUSDT);        
        BLB.transfer(msg.sender, amount);       
        emit BuyInUSDT(amount, payableUSDT);
    }


    /**
     * @dev set ticket price in USD;
     *
     * @notice multiplied by 10^18.
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *
     * @notice emits a SetPriceInUSD event
     */
    function setPriceInUSD(uint256 _priceInUSD) public onlyOwner {
        priceInUSD = _priceInUSD;
        emit SetPriceInUSD(_priceInUSD);
    }

    /**
     * @dev withdraw ERC20 tokens from the contract.
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *
     * @notice emits a Withdraw event
     */
    function withdraw(address tokenAddr, uint256 amount) public onlyOwner {
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