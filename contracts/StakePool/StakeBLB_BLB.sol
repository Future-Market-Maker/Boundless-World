// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IBLBSwap {
    function BLBsForUSD(uint256 amountBUSD) external view returns(uint256);
    function BLBsForBNB(uint256 amountBNB) external view returns(uint256);
}

contract StakeBLB_BLB is Ownable, Pausable {
    IERC20 public BUSD;
    IERC20 public BLB;
    IBLBSwap public BLBSwap;

    uint256 public totalDepositBLB;
    uint256 public totalPendingBLB;

    uint256[] _plans;
    mapping(uint256 => bool) planExists;
    mapping(uint256 => uint256) public rewardPlans;
    mapping(address => Investment[]) public investments;

    Checkpoint checkpoint1;
    Checkpoint checkpoint2;
    Checkpoint checkpoint3;

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

    constructor(
        IERC20 _BUSD,
        IERC20 _BLB,
        address blbSwap
    ) {
        BUSD = _BUSD;
        BLB = _BLB;
        BLBSwap = IBLBSwap(blbSwap);

        setPlan({duration : 3   days, profit: 0.001 * 10 ** 18});  // demo   plan
        setPlan({duration : 30  days, profit: 0.15  * 10 ** 18});  // bronze plan
        setPlan({duration : 90  days, profit: 0.5   * 10 ** 18});  // silver plan
        setPlan({duration : 180 days, profit: 1.2   * 10 ** 18});  // gold   plan
        setPlan({duration : 360 days, profit: 2.5   * 10 ** 18});  // gem    plan

        setCheckpoints({
            passTime1 : 0 , saveDeposit1 : 80 , saveProfit1 : 0,
            passTime2 : 50, saveDeposit2 : 100, saveProfit2 : 0,
            passTime3 : 80, saveDeposit3 : 100, saveProfit3 : 40
        });
    }

    function BLBsForUSD(uint256 amountBUSD) public view returns(uint256){
        return BLBSwap.BLBsForUSD(amountBUSD);
    }

    function BLBsForBNB(uint256 amountBNB) external view returns(uint256){
        return BLBSwap.BLBsForBNB(amountBNB);
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

    function userTotalStake(address investor) public view returns(uint256 totalStake) {
        Investment[] storage invests = investments[investor];
        uint256 len = invests.length;

        for(uint256 i; i < len; i++) {
            if(invests[i].claimTime == 0) {
                totalStake += invests[i].amount;
            }
        }
    }

    function pendingWithdrawal(
        address investor, 
        uint256 investmentId
    ) public view returns(uint256) {

        Investment storage investment = investments[investor][investmentId];

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
            currentTime >= checkpoint3.passTime * duration /100 + start
        ){
            amountDeposit = amount * checkpoint3.saveDeposit / 100;
            amountProfit = profit * checkpoint3.saveProfit / 100;
        } else if(
            currentTime >= checkpoint2.passTime * duration /100 + start
        ){
            amountDeposit = amount * checkpoint2.saveDeposit / 100;
            amountProfit = profit * checkpoint2.saveProfit / 100;
        } else if(
            currentTime >= checkpoint1.passTime * duration /100 + start
        ){
            amountDeposit = amount * checkpoint1.saveDeposit / 100;
            amountProfit = profit * checkpoint1.saveProfit / 100;
        }
        return amountDeposit + amountProfit;
    }

    function pendingWithdrawal(
        address investor
    ) public view returns(uint256 total) {

        uint256 len = investments[investor].length;

        for(uint256 i; i < len; i++) {
            total += pendingWithdrawal(investor, i);
        }
    }

    function buyAndStake(uint256 amountBUSD, uint256 duration) public payable whenNotPaused {
        require(rewardPlans[duration] != 0, "there is no plan by this duration");

        address investor = msg.sender;
        uint256 amount;

        if(amountBUSD != 0) {
            require(msg.value == 0, "not allowed to buy in BUSD and BNB in same time");
            amount = BLBSwap.BLBsForUSD(amountBUSD);
            BUSD.transferFrom(investor, owner(), amountBUSD); 
        } else {
            amount = BLBSwap.BLBsForBNB(msg.value);
            payable(owner()).transfer(msg.value);
        }

        uint256 start = block.timestamp;
        uint256 end = block.timestamp + duration;
        uint256 profit = amount * rewardPlans[duration] / 10 ** 18;

        investments[investor].push(Investment(amount, start, end, profit, 0));

        totalDepositBLB += amount;
        totalPendingBLB += profit;
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

        uint256 amount = pendingWithdrawal(investor, investmentId);

        require(amount > 0, "StakePool: nothing to withdraw");

        investment.claimTime = block.timestamp;

        require(
            BLB.balanceOf(address(this)) > amount, 
            "insufficient BLB balance in the contract"
        );
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

    function checkpoints() public view returns(
        Checkpoint memory checkpoint1_, 
        Checkpoint memory checkpoint2_, 
        Checkpoint memory checkpoint3_
    ){
        checkpoint1_ = checkpoint1;
        checkpoint2_ = checkpoint2;
        checkpoint3_ = checkpoint3;
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
        checkpoint1 = Checkpoint(passTime1, saveDeposit1, saveProfit1);
        checkpoint2 = Checkpoint(passTime2, saveDeposit2, saveProfit2);
        checkpoint3 = Checkpoint(passTime3, saveDeposit3, saveProfit3);
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

    function changeBLBSwap(address _BLBSwap) public onlyOwner {
        BLBSwap = IBLBSwap(_BLBSwap);
    }

    function pay(
        address user,
        uint256 amount
    ) external {
        BLB.transferFrom(msg.sender, user, amount);
    }

    function pay(
        address[] calldata users,
        uint256[] calldata amounts
    ) external {
        uint256 len = users.length;
        require(len == amounts.length, "Lists must be same in length");
        address from = msg.sender;
        for(uint256 i; i < len; i++) {
            BLB.transferFrom(from, users[i], amounts[i]);
        }
    }
    
}