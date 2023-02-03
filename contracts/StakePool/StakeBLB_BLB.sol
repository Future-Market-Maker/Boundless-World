// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakeBLB_BLB is Ownable, Pausable {
    IERC20 public BLB;

    uint256 public totalDepositBLB;
    uint256 public totalPendingBLB;

    uint256[] _plans;
    mapping(uint256 => bool) planExists;
    mapping(uint256 => uint256) public rewardPlans;
    mapping(address => Investment[]) public investments;

    Checkpoint public checkPoint1;
    Checkpoint public checkPoint2;
    Checkpoint public checkPoint3;

    struct Investment {
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 profit;
        uint256 claimTime;
    }

    struct Checkpoint{
        uint256 passTime; //Percent
        uint256 saveDeposit; //Percent
        uint256 saveProfit; //Percent
    }


    constructor(IERC20 _BLB) {
        BLB = _BLB;

        setPlan({duration : 1  days, profit: 0.01 * 10 ** 18});
        setPlan({duration : 7  days, profit: 0.1  * 10 ** 18});
        setPlan({duration : 30 days, profit: 0.5  * 10 ** 18});
        setPlan({duration : 90 days, profit: 1.8  * 10 ** 18});

        setCheckpoints({
            passTime1 : 0 , saveDeposit1 : 80 , saveProfit1 : 0,
            passTime2 : 50, saveDeposit2 : 100, saveProfit2 : 0,
            passTime3 : 80, saveDeposit3 : 100, saveProfit3 : 40
        });
    }

    function releaseTime(
        address investor, 
        uint256 investmentId
    ) public view returns(uint256) {
        return investments[investor][investmentId].end;
    }

    function userInvestments(address investor) public view returns(Investment[] memory) {
        return investments[investor];
    }

    function pendingWithdrawal(
        address investor, 
        uint256 investmentId
    ) public view returns(uint256) {

        Investment storage investment = investments[investor][investmentId];

        require(
            investment.claimTime == 0,
            "stakePool: this investment has been claimed before"
        );
        uint256 amountDeposit; 
        uint256 amountProfit;
        uint256 currentTime = block.timestamp;
        uint256 start = investment.start;
        uint256 end = investment.end; 
        uint256 duration = investment.end - investment.start; 
        uint256 amount = investment.amount; 
        uint256 profit = investment.profit; 

        if(
            currentTime >= end
        ){
            amountDeposit = amount;
            amountProfit = profit;
        } else if(
            currentTime >= checkPoint3.passTime * duration /100 + start
        ){
            amountDeposit = amount * checkPoint3.saveDeposit / 100;
            amountProfit = profit * checkPoint3.saveProfit / 100;
        } else if(
            currentTime >= checkPoint2.passTime * duration /100 + start
        ){
            amountDeposit = amount * checkPoint2.saveDeposit / 100;
            amountProfit = profit * checkPoint2.saveProfit / 100;
        } else if(
            currentTime >= checkPoint1.passTime * duration /100 + start
        ){
            amountDeposit = amount * checkPoint1.saveDeposit / 100;
            amountProfit = profit * checkPoint1.saveProfit / 100;
        }
        return amountDeposit + amountProfit;
    }

    function newInvestment(uint256 amount, uint256 duration) public whenNotPaused {
        require(rewardPlans[duration] != 0, "there is no plan by this duration");

        address investor = msg.sender;
        uint256 start = block.timestamp;
        uint256 end = block.timestamp + duration;
        uint256 profit = amount * rewardPlans[duration] / 10 ** 18;

        BLB.transferFrom(investor, address(this), amount);

        investments[investor].push(Investment(amount, start, end, profit, 0));

        totalDepositBLB += amount;
        totalPendingBLB += profit;
    }

    function withdraw(uint256 investmentId) public {
        address payable investor = payable(msg.sender);

        Investment storage investment = investments[investor][investmentId];

        (uint256 amount) = pendingWithdrawal(investor, investmentId);

        require(amount > 0, "StakePool: nothing to withdraw");

        investment.claimTime = block.timestamp;

        BLB.transfer(investor, amount);

        totalDepositBLB -= investment.amount;
        totalPendingBLB -= investment.profit;
    }

    function plans() public view returns(uint256[] memory durations, uint256[] memory profits) {
        uint256 len = _plans.length;
        durations = new uint256[](len);
        profits = new uint256[](len);

        for(uint256 i = 0; i < len; i++) {
            durations[i] = _plans[i];
            profits[i] = rewardPlans[_plans[i]];
        }
    }

    function setPlan(uint256 duration, uint256 profit) public onlyOwner {
        rewardPlans[duration]  = profit;
        if(!planExists[duration]) {
            planExists[duration] = true;
            _plans.push(duration);
        }
    }

    function setCheckpoints(
        uint256 passTime1, uint256 saveDeposit1, uint256 saveProfit1,
        uint256 passTime2, uint256 saveDeposit2, uint256 saveProfit2,
        uint256 passTime3, uint256 saveDeposit3, uint256 saveProfit3
    ) public onlyOwner {
        checkPoint1 = Checkpoint(passTime1, saveDeposit1, saveProfit1);
        checkPoint2 = Checkpoint(passTime2, saveDeposit2, saveProfit2);
        checkPoint3 = Checkpoint(passTime3, saveDeposit3, saveProfit3);
    }

    function loanBLB(address borrower, uint256 amount) public onlyOwner {
        BLB.transfer(borrower, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
}