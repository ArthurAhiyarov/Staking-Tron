// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error Staking__TransferFailed();

contract StakingTron is Ownable, ReentrancyGuard {

    /* ========== STATE VARIABLES ========== */

    uint256 public s_totalSupply; // total staked balance
    uint public interest; // percent per munite
    uint public fee; // owner's comission
    uint public stakingTime = 3 minutes; // in mins
    uint public ownerFeeBalance; 
    uint public index = 1;
    uint public interestLimit; // is set in the constructor
    uint public feeLimit; // is set in the constructor

    /* =========== STRUCTS =========== */

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
    // staker's address => staker's balance
    mapping(address => uint256) public s_balances;

    /* ========== EVENTS ========== */

    event staked(address stakerAddr, uint amount, uint date);
    event unstaked(address stakerAddr, uint amount, uint date);

    /* ========== CONSTRUCTOR ========== */

    constructor(uint feeRate, uint interestRate, uint _interestLimit, uint _feeLimit) {
        fee = feeRate;
        interest = interestRate;
        interestLimit = _interestLimit;
        feeLimit = _feeLimit;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /** @dev Lets a person stake
      * Emits the staked event
     */

    function stake() external payable nonReentrant {
        require(msg.value != 0, "You cannot stake 0 tokens");
        s_balances[msg.sender] += msg.value;
        s_totalSupply += msg.value;

        if ((stakersIndexes[msg.sender]) == 0) {
            Staker memory newStaker = Staker(
                {
                    stakerAddr: msg.sender,
                    amountStaked: msg.value,
                    stakePeriod: stakingTime,
                    depositStartTime: block.timestamp,
                    depositFinishTime: block.timestamp + stakingTime * 60 * 1 seconds,
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
            existingStakerInList.amountStaked += msg.value;
            existingStaker.stakePeriod = stakingTime;
            existingStakerInList.depositStartTime = block.timestamp;
            existingStakerInList.depositFinishTime = block.timestamp + stakingTime * 60 * 1 seconds;
            existingStakerInList.hasStaked = true;
        }
        emit staked(msg.sender, msg.value, block.timestamp);
    }

    /** @dev Lets a person unstaked their staked tokens and claim a reward
      * @param amount Amount of tokens a caller wants to unstake
      * @return rewardFinal A caller's reward for staking
      * Emits the unstaked event
     */

    function unstakeAndClaimReward(uint256 amount) external returns(uint reward){

        require(amount > 0, "Can not unstake 0");

        uint currentIndex = stakersIndexes[msg.sender];
        require(currentIndex != 0, "You have not staked");
        Staker storage existingStaker = stakersList[currentIndex];

        require(existingStaker.depositFinishTime < block.timestamp, "Your stake has not finished yet");
        require(existingStaker.amountStaked >= amount, "Can not unstake that much");

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
        s_totalSupply -= amount;

        address payable stakerAddress = payable(msg.sender);

        stakerAddress.transfer(stakerAmount + rewardFinal);

        address payable ownerAddress = payable(owner());
        ownerAddress.transfer(ownerFeeBalance);

        emit unstaked(stakerAddress, amount, block.timestamp);
        return rewardFinal;
    }

    /** @dev Changes the interest rate
      * @param newInterest A new interest rate
      * @return interest Updated interest
     */

    function setInterestRate(uint newInterest) external onlyOwner returns(uint _interest) {
        require(newInterest < interestLimit, "Interest must be less than interestLimit");
        interest = newInterest;
        return interest;
    }

    /** @dev Changes staking time
      * @param newTime new staking time
      * @return stakingTime Updated stakingTime
     */

    function setStakingTime3or5or10mins(uint newTime) external onlyOwner returns(uint _stakingTime){
        if (newTime != 3 || newTime != 5 || newTime != 10) 
            revert("Time should be equal to 3/5/10 mins");
        stakingTime = newTime * 1 minutes;
        return stakingTime;
    }

    /** @dev Changes fee rate
      * @param newFee new fee rate
      * @return fee Updated fee
     */

    function setFeeRate(uint newFee) external onlyOwner returns(uint _fee) {
        require(newFee < feeLimit, "Fee must be less than feeLimit");
        fee = newFee;
        return fee;
    }

    /* ========== VIEWS ========== */
    
    /** @dev Provides all info on stakers
      * @return stakersList List of stakers from the storage
     */

    function getStakers() external view returns(Staker[] memory) {
        return stakersList;
    }

    /** @dev Shows total balance on the contract
      * @return s_totalSupply Amount of tokens staked
     */

    function getTotalBalance() external view returns(uint totalSupply){
        return s_totalSupply;
    }

    /** @dev Shows balance of the caller
      * @return s_balances[msg.sender] Amount of the caller's staked tokens 
     */

    function getStakerBalance() external view returns(uint yourBalance) {
        return s_balances[msg.sender];
    }
}