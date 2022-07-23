// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title staking pool 
 * @notice every one can stake BNB and get BLB as benefit.
 */
contract StakePool {
    
    IERC20 immutable BLB = IERC20(address(0));

    uint256 totalProfits;

    uint256 totalFunds;
    uint256 totalDurations;

    mapping(address => investment) investments;

    struct Investment {
        uint256 amount;
        uint256 start;
        uint256 duration;
        uint256 profit;
    }

    function profit(address investor) public view returns(uint256) {
        Investment memory investment = investments[investor];
        
        totalShare = totalFunds * totalDurations;
        investorShare = investment.profit + investment.amount * investment.duration;

        return investment.start + investment.duration >= block.timestamp ?
        investorShare * totalProfits / totalShare :
        0;
    }

    function invest(uint256 investingTime) public payable {
        totalFunds += msg.value;
        totalDurations += investingTime;
        investments[msg.sender] = Investment(msg.value, block.timestamp, investingTime, 0);
    }

    function increaseFund(uint256 investingTime) public payable {
        totalFunds += msg.value;
        totalDurations += investingTime;
        investments[msg.sender] = Investment(msg.value, block.timestamp, investingTime, 0);
    }

    function withdrawFund(uint256 amount) public {
        address investor = msg.sender;
        // check if investor has enough funds to withdraw
        assert(investments[investor].amount >= amount);

        // decrease total funds and investor funds
        totalFunds -= amount;
        investments[investor].amount -= amount;

        //transfer required BNB fund to the investor
        payable(investor).transfer(amount);

        //transfer BLB profit to the investor(if duration passed)
        uint256 _profit = profit(investor);
        if (_profit > 0) {
            BLB.transfer(investor, _profit);
        }
    }
}