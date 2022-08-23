// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title staking pool 
 * @notice every one can stake BNB and get BLB as benefit.
 */
contract BNBStakePool is Pausable, Ownable {
    
    // BLB address on rinkeby
    IERC20 immutable BLB = IERC20(0x880BA82fcC12fE7De255FA62C9d0beFb7960c986);

    uint256 public totalInvestingBNB;
    uint256 public totalPendingBLB;

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
        uint256 saveBNB; //Percent
        uint256 saveBLB; //Percent
    }

    event NewInvest(
        address indexed investor, 
        uint256 indexed investId, 
        uint256 amount, 
        uint256 start,
        uint256 end,
        uint256 profit
    );

    constructor() {
        rewardPlans[1 days]  = 1   * 10 ** 18;
        rewardPlans[7 days]  = 10  * 10 ** 18;
        rewardPlans[30 days] = 50  * 10 ** 18;
        rewardPlans[90 days] = 180 * 10 ** 18;

        setCheckpoints({
            passTime1 : 0 , saveBNB1 : 80 , saveBLB1 : 0,
            passTime2 : 50, saveBNB2 : 100, saveBLB2 : 0,
            passTime3 : 80, saveBNB3 : 100, saveBLB3 : 40
        });
    }

    function pendingWithdrawal(address investor, uint256 investmentId) public view returns(
        uint256 amountBNB,
        uint256 amountBLB
    ) {
        Investment storage invest = investments[investor][investmentId];

        require(
            invest.claimTime == 0,
            "stakePool: this invest has been claimed before"
        );

        uint256 currentTime = block.timestamp;
        uint256 start = invest.start;
        uint256 end = invest.end; 
        uint256 duration = invest.end - invest.start; 
        uint256 amount = invest.amount; 
        uint256 profit = invest.profit; 

        if(
            currentTime > end
        ){
            amountBNB = amount;
            amountBLB = profit;
        } else if(
            currentTime > checkPoint3.passTime * duration /100 + start
        ){
            amountBNB = amount * checkPoint3.saveBNB / 100;
            amountBLB = profit * checkPoint3.saveBLB / 100;
        } else if(
            currentTime > checkPoint2.passTime * duration /100 + start
        ){
            amountBNB = amount * checkPoint2.saveBNB / 100;
            amountBLB = profit * checkPoint2.saveBLB / 100;
        } else if(
            currentTime > checkPoint1.passTime * duration /100 + start
        ){
            amountBNB = amount * checkPoint1.saveBNB / 100;
            amountBLB = profit * checkPoint1.saveBLB / 100;
        }
    }

    function newInvest(uint256 duration) public payable whenNotPaused {
        require(rewardPlans[duration] != 0, "there is no plan by this duration");

        address investor = msg.sender;
        uint256 amount = msg.value;
        uint256 start = block.timestamp;
        uint256 end = block.timestamp + duration;
        uint256 profit = amount * rewardPlans[duration] / 10 ** 18;

        investments[investor].push(Investment(amount, start, end, profit, 0));

        totalInvestingBNB += amount;
        totalPendingBLB += profit;

        emit NewInvest(investor, investments[investor].length-1, amount, start, end, profit);
    }

    function withdraw(uint256 investmentId) public {
        address payable claimant = payable(msg.sender);

        Investment storage invest = investments[claimant][investmentId];

        (uint256 amountBNB, uint256 amountBLB) = pendingWithdrawal(claimant, investmentId);

        require(amountBNB > 0, "StakePool: nothing to withdraw");

        invest.claimTime = block.timestamp;

        claimant.transfer(amountBNB);
        BLB.transfer(claimant, amountBLB);

        totalInvestingBNB -= invest.amount;
        totalPendingBLB -= invest.profit;
    }

    function setCheckpoints(
        uint256 passTime1, uint256 saveBNB1, uint256 saveBLB1,
        uint256 passTime2, uint256 saveBNB2, uint256 saveBLB2,
        uint256 passTime3, uint256 saveBNB3, uint256 saveBLB3
    ) public onlyOwner {
        checkPoint1 = Checkpoint(passTime1, saveBNB1, saveBLB1);
        checkPoint1 = Checkpoint(passTime2, saveBNB2, saveBLB2);
        checkPoint1 = Checkpoint(passTime3, saveBNB3, saveBLB3);
    }

    function loanBNB(address borrower, uint256 amount) public onlyOwner {
        payable(borrower).transfer(amount);
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