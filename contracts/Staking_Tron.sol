// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Staking__TransferFailed();

contract StakingTron is Ownable {

    // IERC20 immutable public trxToken;

    mapping(address => uint256) public s_balances;

    uint256 public s_totalSupply; // total staked balance
    uint public interest; // percent per munite
    uint public fee;
    uint public ownerFeeBalance; 
    uint public index = 1;

    struct Staker {
        address stakerAddr;
        uint amountStaked;
        uint stakePeriod;
        uint depositStartTime;
        uint depositFinishTime;
        bool hasStaked;
        uint index;
    }

    Staker[] public stakersList;
    mapping(address => uint) public stakersIndexes;

    constructor(uint feeRate, uint interestRate) {
        // trxToken = IERC20(_trxToken);
        fee = feeRate;
        interest = interestRate;
    }

    function stake(uint256 amount, uint timeInMinutes) public payable {
        require(amount != 0, "You cannot stake 0 tokens");
        s_balances[msg.sender] += amount;
        s_totalSupply += amount;

        if ((stakersIndexes[msg.sender]) == 0) {
            Staker memory newStaker = Staker(
                {
                    stakerAddr: msg.sender,
                    amountStaked: amount,
                    stakePeriod: timeInMinutes,
                    depositStartTime: block.timestamp,
                    depositFinishTime: block.timestamp + timeInMinutes * 60,
                    hasStaked: true,
                    index: index - 1
                }
            );
            stakersIndexes[msg.sender] = index;
            index++;
            stakersList.push(newStaker);
        } else {
            uint currentIndex = stakersIndexes[msg.sender];
            Staker storage existingStaker = stakersList[currentIndex];
            require(existingStaker.hasStaked == false, 'You have already staked');
            Staker storage existingStakerInList = stakersList[existingStaker.index];
            existingStakerInList.amountStaked += amount;
            existingStaker.stakePeriod = timeInMinutes;
            existingStakerInList.depositStartTime = block.timestamp;
            existingStakerInList.depositFinishTime = block.timestamp + timeInMinutes;
            existingStakerInList.hasStaked = true;
        }
        // bool success = trxToken.transferFrom(msg.sender, address(this), amount);
        // if(!success) {
        //     revert Staking__TransferFailed(); 
        // }
    }

    function stakeFor3minutes(uint256 amount) public payable {
        stake(amount, 3);
    }

    function stakeFor5minutes(uint256 amount) public payable {
        stake(amount, 5);
    }

    function stakeFor10minutes(uint256 amount) public payable{
        stake(amount, 10);
    }

    function unstakeAndClaimReward(uint256 amount) public returns(uint reward){

        uint currentIndex = stakersIndexes[msg.sender];
        Staker storage existingStaker = stakersList[currentIndex];

        require(existingStaker.depositFinishTime < block.timestamp, "Your stake has not finished yet");
        require(existingStaker.amountStaked >= amount, "Can not unstake that much");
        require(amount > 0, "Can not unstake 0");

        uint rewardRaw = (existingStaker.amountStaked / 100) * interest * existingStaker.stakePeriod;
        uint ownerFee = (rewardRaw / 100) * fee;
        uint rewardFinal = rewardRaw - ownerFee;
        // uint stakerAmount = existingStaker.amountStaked;

        ownerFeeBalance += ownerFee;


        existingStaker.amountStaked -= amount;
        existingStaker.stakePeriod = 0;
        existingStaker.depositStartTime = 0;
        existingStaker.depositFinishTime = 0;
        existingStaker.hasStaked = false;

        s_balances[msg.sender] -= amount;

        // bool successUnstake = trxToken.transfer(msg.sender, stakerAmount + rewardFinal);
        // if(!successUnstake) {
        //     revert Staking__TransferFailed();
        // }

        // bool successOwnerFee = trxToken.transfer(owner(), ownerFeeBalance);
        // if(!successOwnerFee) {
        //     revert Staking__TransferFailed();
        // }

        return rewardFinal;

    }
    
    function getStakers() public view returns(Staker[] memory) {
        return stakersList;
    }

    function getTotalBalance() public view returns(uint totalSupply){
        return s_totalSupply;
    }

    function setInterestFee(uint newInterest) external onlyOwner returns(uint _interest) {
        interest = newInterest;
        return interest;
    }

    function setFeeRate(uint newFee) external onlyOwner returns(uint _fee) {
        fee = newFee;
        return fee;
    }
}