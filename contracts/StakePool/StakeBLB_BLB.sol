// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IBLBSwap {
    function BLBsForUSD(uint256 amountBUSD) external view returns(uint256);
    function BLBsForBNB(uint256 amountBNB) external view returns(uint256);
}


contract StakeBLB_BLB is Ownable, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public BUSD;
    IERC20 public BLB;
    IBLBSwap public BLBSwap;

    uint256 public totalDepositBLB;
    uint256 public totalPendingBLB;

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
        address blbSwap,
        uint256[] memory _timePlans_,
        uint256[] memory _investPlanAmounts_,
        uint256[] memory _investPlanProfits_
    ) {
        BUSD = _BUSD;
        BLB = _BLB;
        BLBSwap = IBLBSwap(blbSwap);

        setCheckpoints({
            passTime1 : 0 , saveDeposit1 : 80 , saveProfit1 : 0,
            passTime2 : 50, saveDeposit2 : 100, saveProfit2 : 0,
            passTime3 : 80, saveDeposit3 : 100, saveProfit3 : 40
        });

        uint256 timePlanLen = _timePlans_.length;
        for(uint256 i; i < timePlanLen; i ++) {
            _timePlans.add(_timePlans_[i]);
        }

        setInvestPlans(_investPlanAmounts_, _investPlanProfits_);
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

    function buyAndStake(uint256 amountBUSD, uint256 timeInDays) public payable whenNotPaused {
        require(_timePlans.contains(timeInDays), "there is no such time plan available");
        uint256 duration = timeInDays * 1 days;

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
        uint256 profit = profitCalculator(amount, duration);

        investments[investor].push(Investment(amount, start, end, profit, 0));

        totalDepositBLB += amount;
        totalPendingBLB += profit;
    }

    function newInvestment(uint256 amount, uint256 timeInDays) public whenNotPaused {
        require(_timePlans.contains(timeInDays), "there is no such time plan available");
        uint256 duration = timeInDays * 1 days;

        address investor = msg.sender;
        uint256 start = block.timestamp;
        uint256 end = block.timestamp + duration;
        uint256 profit = profitCalculator(amount, duration);

        BLB.transferFrom(investor, address(this), amount);

        investments[investor].push(Investment(amount, start, end, profit, 0));

        totalDepositBLB += amount;
        totalPendingBLB += profit;
    }

    function topUpPayable(uint256 amountBUSD, uint256 investmentId) public payable whenNotPaused {

        uint256 addingAmount;
        address investor = msg.sender;

        if(amountBUSD != 0) {
            require(msg.value == 0, "not allowed to topUp in BUSD and BNB in same time");
            addingAmount = BLBSwap.BLBsForUSD(amountBUSD);
            BUSD.transferFrom(investor, owner(), amountBUSD); 
        } else {
            addingAmount = BLBSwap.BLBsForBNB(msg.value);
            payable(owner()).transfer(msg.value);
        }

        uint256 currentTime = block.timestamp;
        Investment memory investment = investments[investor][investmentId];
        uint256 wholeTime = investment.end - investment.start;
        require(currentTime < investment.end, "investment expired");
        uint256 oldProfit = investment.profit * (currentTime - investment.start) / wholeTime;
        uint256 newProfit = profitCalculator(investment.amount + addingAmount, investment.end - currentTime);

        require(oldProfit + newProfit > investment.profit, "the profit is not increasing");
        uint256 addingProfit = oldProfit + newProfit - investment.profit;

        investments[investor][investmentId].amount += addingAmount;
        investments[investor][investmentId].profit += addingProfit;
        
        totalDepositBLB += addingAmount;
        totalPendingBLB += addingProfit;
    }

    function topUp(uint256 addingAmount, uint256 investmentId) public whenNotPaused {

        address investor = msg.sender;
        uint256 currentTime = block.timestamp;
        Investment memory investment = investments[investor][investmentId];
        uint256 wholeTime = investment.end - investment.start;
        require(currentTime < investment.end, "investment expired");
        uint256 oldProfit = investment.profit * (currentTime - investment.start) / wholeTime;
        uint256 newProfit = profitCalculator(investment.amount + addingAmount, investment.end - currentTime);

        require(oldProfit + newProfit > investment.profit, "the profit is not increasing");
        uint256 addingProfit = oldProfit + newProfit - investment.profit;

        BLB.transferFrom(investor, address(this), addingAmount);

        investments[investor][investmentId].amount += addingAmount;
        investments[investor][investmentId].profit += addingProfit;
        
        totalDepositBLB += addingAmount;
        totalPendingBLB += addingProfit;
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

    function checkpoints() public view returns(
        Checkpoint memory checkpoint1_, 
        Checkpoint memory checkpoint2_, 
        Checkpoint memory checkpoint3_
    ){
        checkpoint1_ = checkpoint1;
        checkpoint2_ = checkpoint2;
        checkpoint3_ = checkpoint3;
    }

    function setCheckpoints(
        uint256 passTime1, uint256 saveDeposit1, uint256 saveProfit1,
        uint256 passTime2, uint256 saveDeposit2, uint256 saveProfit2,
        uint256 passTime3, uint256 saveDeposit3, uint256 saveProfit3
    ) public onlyOwner {
        require(
            passTime1 < passTime2 && passTime2 < passTime3, 
            "Pass Times must be increasing in a row"
        );
        require(
            saveDeposit1 <= saveDeposit2 && saveDeposit2 <= saveDeposit3, 
            "Pass Times must be same or increasing in a row"
        );
        require(
            saveProfit1 <= saveProfit2 && saveProfit2 <= saveProfit3, 
            "Pass Times must be same or increasing in a row"
        );
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


// time plans -----------------------------------------------------------------------------------

    EnumerableSet.UintSet _timePlans;

    function removeTimePlan(uint256 timeInDays) public onlyOwner {
        require(_timePlans.contains(timeInDays), "Time plans must exist in _timePlans");
        _timePlans.remove(timeInDays);
    }

    function addTimePlan(uint256 timeInDays) public onlyOwner {
        require(!_timePlans.contains(timeInDays), "Time plan already exists in _timePlans");
        _timePlans.add(timeInDays);
    }

    function timePlans() public view returns(uint256[] memory){
        return _timePlans.values();
    }

// profit plans ---------------------------------------------------------------------------------
    uint256[] _investPlanAmounts;
    uint256[] _investPlanProfits;

    function setInvestPlans(
        uint256[] memory _investPlanAmounts_,
        uint256[] memory _investPlanProfits_
    ) public onlyOwner {
        uint256 len = _investPlanAmounts_.length;
        require(len ==_investPlanProfits_.length, "arrays length must be same");
        for(uint256 i = 1; i < len; i++) {
            require(
                _investPlanAmounts_[i] > _investPlanAmounts_[i-1],
                "amounts must be increasing in a row"
            );
            require(
                _investPlanProfits_[i] >= _investPlanProfits_[i-1],
                "profits must be same or increasing in a row"
            );
        }
        _investPlanAmounts = _investPlanAmounts_;
        _investPlanProfits = _investPlanProfits_;
    }

    function investPlans() public view returns(
        uint256[] memory _investPlanAmounts_, // [ 10 * 10e18, 100 * 10e18, 1000 * 10e18]
        uint256[] memory _investPlanProfits_  // [ 300, 500, 1200]
    ) {
        _investPlanAmounts_ = _investPlanAmounts;
        _investPlanProfits_ = _investPlanProfits;
    }


// profit calculator -------------------------------------------------------------------

    function profitCalculator(uint256 investingAmount, uint256 duration) public view returns(uint256 profit) {
        uint256 len = _investPlanAmounts.length;
        for(uint256 i = len; i > 0; i--) {
            if(investingAmount >= _investPlanAmounts[i - 1]) {
                profit = investingAmount * _investPlanProfits[i - 1]/10000 * duration / 30 days;
                break;
            }
        }
        require(profit != 0, "no plan for this amount");
    }
    
}