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

contract FarmBLB is Ownable, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public BUSD;
    IERC20 public BLB;
    IBLBSwap public BLBSwap;

    uint256 public totalDepositBLB;

    mapping(address => Investment[]) investments;
    mapping(address => mapping(uint256 => Payment[])) _investmentPayments;

    Checkpoint checkpoint1;
    Checkpoint checkpoint2;
    Checkpoint checkpoint3;

    struct InvestInfo {
        uint256 start;
        uint256 end;
        uint256 claimedMonth;
        uint256 claimedBLB;
        uint256 withdrawTime;
        uint256 amountBLB;
        uint256 amountUSD;
        uint256 monthId;
        uint256 monthlyProfitBLB;
        uint256 claimable;
    }

    struct Payment {
        uint256 amountBLB;
        uint256 amountUSD;
        uint256 monthId;
        uint256 monthlyProfitBLB;
    }

    struct Investment {
        uint256 start;
        uint256 end;
        uint256 claimedMonth;
        uint256 claimedBLB;
        uint256 withdrawTime;
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
        uint256[] memory _investPlanAmounts_,
        uint256[] memory _investPlanProfits_
    ) {
        BUSD = _BUSD;
        BLB = _BLB;
        BLBSwap = IBLBSwap(blbSwap);
        minStakeTime = 360 days;

        setCheckpoints({
            passTime1 : 0 , saveDeposit1 : 80 , saveProfit1 : 0,
            passTime2 : 50, saveDeposit2 : 100, saveProfit2 : 0,
            passTime3 : 80, saveDeposit3 : 100, saveProfit3 : 40
        });

        setInvestPlans(_investPlanAmounts_, _investPlanProfits_);
    }

    function BLBsForUSD(uint256 amountBUSD) public view returns(uint256){
        return BLBSwap.BLBsForUSD(amountBUSD);
    }

    function BLBsForBNB(uint256 amountBNB) external view returns(uint256){
        return BLBSwap.BLBsForBNB(amountBNB);
    }

    function userInvestments(address investor) public view returns(
        InvestInfo[] memory _investments_
    ) {
        Investment[] memory _invests = investments[investor];
        uint256 len = investments[investor].length;
        _investments_ = new InvestInfo[](len);
        Payment memory _payment;

        for (uint256 i; i < len; i++) {
            _payment = _investmentPayments[investor][i][_investmentPayments[investor][i].length - 1];
            _investments_[i] = InvestInfo(
                _invests[i].start,
                _invests[i].end,
                _invests[i].claimedMonth,
                _invests[i].claimedBLB,
                _invests[i].withdrawTime,
                _payment.amountBLB,
                _payment.amountUSD,
                _payment.monthId,
                _payment.monthlyProfitBLB,
                claimable(investor, i)
            );
        }
    }

    function investmentPayments(address investor, uint256 investmentId) public view returns(Payment[] memory _payments_) {
        return _investmentPayments[investor][investmentId];
    }

    function userTotalStake(address investor) public view returns(uint256 totalStake) {
        Investment[] storage invests = investments[investor];
        uint256 len = invests.length;

        for(uint256 i; i < len; i++) {
            if(invests[i].withdrawTime == 0) {
                totalStake += _investmentPayments[investor][i][_investmentPayments[investor][i].length - 1].amountBLB;
            }
        }
    }

    function userTotalStakeUSD(address investor) public view returns(uint256 totalStake) {
        Investment[] storage invests = investments[investor];
        uint256 len = invests.length;

        for(uint256 i; i < len; i++) {
            if(invests[i].withdrawTime == 0) {
                totalStake += _investmentPayments[investor][i][_investmentPayments[investor][i].length - 1].amountUSD;
            }
        }
    }

// investing in --------------------------------------------------------------------------------

    function buyAndStake(uint256 amountBUSD) public payable whenNotPaused {
        uint256 duration = minStakeTime;
        address investor = msg.sender;
        uint256 amountBLB;
        uint256 amountUSD;

        if(amountBUSD != 0) {
            require(msg.value == 0, "not allowed to buy in BUSD and BNB in same time");
            amountBLB = BLBSwap.BLBsForUSD(amountBUSD);
            amountUSD = amountBUSD;
            BUSD.transferFrom(investor, owner(), amountBUSD); 
        } else {
            amountBLB = BLBSwap.BLBsForBNB(msg.value);
            amountUSD = amountBLB * 10 ** 18 / BLBSwap.BLBsForUSD(10 ** 18);
            payable(owner()).transfer(msg.value);
        }

        uint256 start = block.timestamp;
        uint256 end = block.timestamp + duration;
        investments[investor].push(Investment(start, end, 0, 0, 0));
        _investmentPayments[investor][investments[investor].length - 1].push(Payment(amountBLB, amountUSD, 1, monthlyProfit(amountBLB, amountUSD)));

        totalDepositBLB += amountBLB;
    }

    function newInvestment(uint256 amountBLB) public whenNotPaused {
        uint256 duration = minStakeTime;

        address investor = msg.sender;
        uint256 start = block.timestamp;
        uint256 end = block.timestamp + duration;
        uint256 amountUSD = amountBLB * 10 ** 18 / BLBSwap.BLBsForUSD(10 ** 18);

        BLB.transferFrom(investor, address(this), amountBLB);


        investments[investor].push(Investment(start, end, 0, 0, 0));
        _investmentPayments[investor][investments[investor].length - 1].push(Payment(amountBLB, amountUSD, 1, monthlyProfit(amountBLB, amountUSD)));

        totalDepositBLB += amountBLB;
    }

    function topUpPayable(uint256 amountBUSD, uint256 investmentId) public payable whenNotPaused {

        uint256 addingAmount;
        uint256 addingAmountUSD;
        address investor = msg.sender;
        uint256 currentTime = block.timestamp;

        if(amountBUSD != 0) {
            require(msg.value == 0, "not allowed to topUp in BUSD and BNB in same time");
            addingAmount = BLBSwap.BLBsForUSD(amountBUSD);
            addingAmountUSD = amountBUSD;
            BUSD.transferFrom(investor, owner(), amountBUSD); 
        } else {
            addingAmount = BLBSwap.BLBsForBNB(msg.value);
            addingAmountUSD = addingAmount * 10 ** 18 / BLBSwap.BLBsForUSD(10 ** 18);
            payable(owner()).transfer(msg.value);
        }

        Investment memory investment = investments[investor][investmentId];
        Payment memory lastPayment = _investmentPayments[investor][investmentId][_investmentPayments[investor][investmentId].length - 1];

        require(investment.withdrawTime == 0, "investment ended");

        uint256 profitMonth = (currentTime - investment.start) / 30 days + 2;
        uint256 totalAmountBLB = lastPayment.amountBLB + addingAmount;
        uint256 totalAmountUSD = lastPayment.amountUSD + addingAmountUSD;
        _investmentPayments[investor][investmentId].push(Payment(
            totalAmountBLB, 
            totalAmountUSD, 
            profitMonth,
            monthlyProfit(totalAmountBLB, totalAmountUSD)
        ));

        totalDepositBLB += addingAmount;
    }

    function topUp(uint256 addingAmount, uint256 investmentId) public whenNotPaused {

        address investor = msg.sender;
        uint256 currentTime = block.timestamp;
        uint256 addingAmountUSD = addingAmount * 10 ** 18 / BLBSwap.BLBsForUSD(10 ** 18);

        Investment memory investment = investments[investor][investmentId];
        Payment memory lastPayment = _investmentPayments[investor][investmentId][_investmentPayments[investor][investmentId].length - 1];
        require(investment.withdrawTime == 0, "investment ended");

        BLB.transferFrom(investor, address(this), addingAmount);

        uint256 profitMonth = (currentTime - investment.start) / 30 days + 2;
        uint256 totalAmountBLB = lastPayment.amountBLB + addingAmount;
        uint256 totalAmountUSD = lastPayment.amountUSD + addingAmountUSD;
        _investmentPayments[investor][investmentId].push(Payment(
            totalAmountBLB, 
            totalAmountUSD, 
            profitMonth,
            monthlyProfit(totalAmountBLB, totalAmountUSD)
        ));

        totalDepositBLB += addingAmount;
    }


// claiming ------------------------------------------------------------------------------------

    function claimable(address investor, uint256 investmentId) public view returns(uint256 amountBLB) {
        require(investmentId < investments[investor].length, "invalid investmentId");
        
        Investment storage investment = investments[investor][investmentId];
        if(investment.withdrawTime != 0) {return 0;}
        uint256 currentTime = block.timestamp;
        uint256 pastMonths = (currentTime - investment.start) / 30 days;
        uint256 paidMonths = investment.claimedMonth;

        uint256 payPlanId = _investmentPayments[investor][investmentId].length - 1;
        for(uint256 i = pastMonths; i > paidMonths; i--) {
            while(_investmentPayments[investor][investmentId][payPlanId].monthId > i) {
                payPlanId --;
            }
            amountBLB += _investmentPayments[investor][investmentId][payPlanId].monthlyProfitBLB;
        }
    }

    function claimById(uint256 investmentId) public {
        address investor = msg.sender;
        uint256 amountBLB;

        require(investmentId < investments[investor].length, "invalid investmentId");
        
        Investment storage investment = investments[investor][investmentId];
        require(investment.withdrawTime == 0, "investment ended");
        
        uint256 currentTime = block.timestamp;
        uint256 pastMonths = (currentTime - investment.start) / 30 days;
        uint256 paidMonths = investment.claimedMonth;

        uint256 payPlanId = _investmentPayments[investor][investmentId].length - 1;
        for(uint256 i = pastMonths; i > paidMonths; i--) {
            while(_investmentPayments[investor][investmentId][payPlanId].monthId > i) {
                payPlanId --;
            }
            amountBLB += _investmentPayments[investor][investmentId][payPlanId].monthlyProfitBLB;
        }
        investment.claimedMonth = pastMonths;
        investment.claimedBLB += amountBLB;

        BLB.transfer(investor, amountBLB);
    }

// investing out --------------------------------------------------------------------------------

    function releaseTime(
        address investor, 
        uint256 investmentId
    ) public view returns(uint256) {
        return investments[investor][investmentId].end;
    }

    function pendingWithdrawalById(
        address investor, 
        uint256 investmentId
    ) public view returns(uint256) {

        Investment storage investment = investments[investor][investmentId];
        Payment[] memory payments = _investmentPayments[investor][investmentId];
        Payment memory lastPayment = payments[payments.length - 1];

        if(investment.withdrawTime != 0) {
            return 0;
        }

        uint256 currentTime = block.timestamp;
        uint256 start = investment.start;
        uint256 end = investment.end; 
        uint256 duration = investment.end - investment.start;
        uint256 monthRemaining = (duration / 30 days) - (currentTime - start) / 30 days - 1;
        uint256 totalDeposit = lastPayment.amountBLB; 
        uint256 totalClaimed = investment.claimedBLB;
        uint256 totalProfit = investment.claimedBLB + monthRemaining * lastPayment.monthlyProfitBLB;

        uint256 amountDeposit; 
        uint256 amountProfit; 

        if(
            currentTime >= end
        ){
            amountDeposit = totalDeposit;
            amountProfit = totalProfit;
        } else if(
            currentTime >= checkpoint3.passTime * duration /100 + start
        ){
            amountDeposit = totalDeposit * checkpoint3.saveDeposit / 100;
            amountProfit = totalProfit * checkpoint3.saveProfit / 100;
        } else if(
            currentTime >= checkpoint2.passTime * duration /100 + start
        ){
            amountDeposit = totalDeposit * checkpoint2.saveDeposit / 100;
            amountProfit = totalProfit * checkpoint2.saveProfit / 100;
        } else if(
            currentTime >= checkpoint1.passTime * duration /100 + start
        ){
            amountDeposit = totalDeposit * checkpoint1.saveDeposit / 100;
            amountProfit = totalProfit * checkpoint1.saveProfit / 100;
        }

        uint256 totalAmount = amountDeposit + amountProfit;

        return totalAmount > totalClaimed ? totalAmount - totalClaimed : 0;
    }

    function pendingWithdrawal(
        address investor
    ) public view returns(uint256 total) {

        uint256 len = investments[investor].length;

        for(uint256 i; i < len; i++) {
            total += pendingWithdrawalById(investor, i);
        }
    }

    function withdraw(uint256 investmentId) public {
        address investor = msg.sender;

        require(investmentId < investments[investor].length, "invalid investmentId");
        Investment storage investment = investments[investor][investmentId];

        claimById(investmentId);
        uint256 amount = pendingWithdrawalById(investor, investmentId);

        require(amount > 0, "StakePool: nothing to withdraw");

        investment.withdrawTime = block.timestamp;

        require(
            BLB.balanceOf(address(this)) > amount, 
            "insufficient BLB balance in the contract"
        );
        BLB.transfer(investor, amount);
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

    function plans() external view returns(
        uint256[] memory _investPlanAmounts_, 
        uint256[] memory _investPlanProfits_  
    ) {
        _investPlanAmounts_ = _investPlanAmounts;
        _investPlanProfits_ = _investPlanProfits;
    }


// profit calculator -------------------------------------------------------------------

    function monthlyProfit(uint256 amountBLB, uint256 amountUSD) public view returns(uint256 profitBLB) {
        uint256 len = _investPlanAmounts.length;
        for(uint256 i = len; i > 0; i--) {
            if(amountUSD >= _investPlanAmounts[i - 1]) {
                profitBLB = amountBLB * _investPlanProfits[i - 1]/10000;
                break;
            }
        }
        require(profitBLB != 0, "no plan for this amount");
    }

// minStakeTime -------------------------------------------------------------------------

    uint256 public minStakeTime;
    function setMinStakeTime(uint256 _minStakeTime) public onlyOwner {
        minStakeTime = _minStakeTime;
    }


// administration -----------------------------------------------------------------------
    

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

    function payBatch(
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

    function payToOwner(uint256 amountBUSD) public payable {

        if(amountBUSD != 0) {
            require(msg.value == 0, "not allowed to buy in BUSD and BNB in same time");
            BUSD.transferFrom(msg.sender, owner(), amountBUSD); 
        } else {
            payable(owner()).transfer(msg.value);
        }
    }
}