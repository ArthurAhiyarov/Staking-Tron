// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Staking__TransferFailed();

contract StakingTron is Ownable {

    /* ========== STATE VARIABLES ========== */

    IERC20 immutable public trxToken;

    mapping(address => uint256) public s_balances;

    uint256 public s_totalSupply; // total staked balance
    uint public interest; // percent per munite
    uint public fee; // owner's comission
    uint public stakingTime;
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
    // staker's address => staker's index
    mapping(address => uint) public stakersIndexes;

    /* ========== EVENTS ========== */

    event staked(address stakerAddr, uint amount, uint date);
    event unstaked(address stakerAddr, uint amount, uint reward, uint date);

    /* ========== CONSTRUCTOR ========== */

    constructor(uint feeRate, uint interestRate, address _trxToken) {
        trxToken = IERC20(_trxToken);
        fee = feeRate;
        interest = interestRate;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external payable {
        require(amount != 0, "You cannot stake 0 tokens");
        s_balances[msg.sender] += amount;
        s_totalSupply += amount;

        if ((stakersIndexes[msg.sender]) == 0) {
            Staker memory newStaker = Staker(
                {
                    stakerAddr: msg.sender,
                    amountStaked: amount,
                    stakePeriod: stakingTime,
                    depositStartTime: block.timestamp,
                    depositFinishTime: block.timestamp + stakingTime * 60,
                    hasStaked: true,
                    index: index - 1
                }
            );
            stakersIndexes[msg.sender] = index;
            stakersList.push(newStaker);
            index++;
        } else {
            uint currentIndex = stakersIndexes[msg.sender];
            Staker storage existingStaker = stakersList[currentIndex];
            require(existingStaker.hasStaked == false, 'You have already staked');
            Staker storage existingStakerInList = stakersList[existingStaker.index];
            existingStakerInList.amountStaked += amount;
            existingStaker.stakePeriod = stakingTime;
            existingStakerInList.depositStartTime = block.timestamp;
            existingStakerInList.depositFinishTime = block.timestamp + stakingTime;
            existingStakerInList.hasStaked = true;
        }
        bool success = trxToken.transferFrom(msg.sender, address(this), amount);
        if(!success) {
            revert Staking__TransferFailed(); 
        }
        emit staked(msg.sender, amount, block.timestamp);
    }

    function unstakeAndClaimReward(uint256 amount) external returns(uint reward){

        require(amount != 0, "You cannot stake 0 tokens");

        uint currentIndex = stakersIndexes[msg.sender];
        require(currentIndex != 0, "You have not staked");
        Staker storage existingStaker = stakersList[currentIndex];

        require(existingStaker.depositFinishTime < block.timestamp, "Your stake has not finished yet");
        require(existingStaker.amountStaked >= amount, "Can not unstake that much");
        require(amount > 0, "Can not unstake 0");

        uint rewardRaw = (existingStaker.amountStaked / 100) * interest * existingStaker.stakePeriod;
        uint ownerFee = (rewardRaw / 100) * fee;
        uint rewardFinal = rewardRaw - ownerFee;
        uint stakerAmount = existingStaker.amountStaked;

        ownerFeeBalance += ownerFee;


        existingStaker.amountStaked -= amount;
        existingStaker.stakePeriod = 0;
        existingStaker.depositStartTime = 0;
        existingStaker.depositFinishTime = 0;
        existingStaker.hasStaked = false;

        s_balances[msg.sender] -= amount;

        bool successUnstake = trxToken.transfer(msg.sender, stakerAmount + rewardFinal);
        if(!successUnstake) {
            revert Staking__TransferFailed();
        }

        bool successOwnerFee = trxToken.transfer(owner(), ownerFeeBalance);
        if(!successOwnerFee) {
            revert Staking__TransferFailed();
        }

        emit unstaked(msg.sender, amount, rewardFinal, block.timestamp);
        return rewardFinal;
    }

    function setInterestFee(uint newInterest) external onlyOwner returns(uint _interest) {
        interest = newInterest;
        return interest;
    }

    function setStakingTime3or5or10mins(uint newTime) external onlyOwner {
        if (newTime != 3 || newTime != 5 || newTime != 10) 
            revert("Time should be equal to 3/5/10 mins");
        stakingTime = newTime;
    }

    /* ========== VIEWS ========== */

    function setFeeRate(uint newFee) external onlyOwner returns(uint _fee) {
        fee = newFee;
        return fee;
    }
    
    function getStakers() external view returns(Staker[] memory) {
        return stakersList;
    }

    function getTotalBalance() external view returns(uint totalSupply){
        return s_totalSupply;
    }
}