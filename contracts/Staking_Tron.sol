// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();

contract StakingTron {

    // IERC20 immutable public trxToken;

    mapping(address => uint256) public s_balances;

    uint256 public s_totalSupply; // total staked balance
    uint public interest; // percent per munite
    uint public fee; 
    uint index = 0;
    address ownerAddr;

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
        ownerAddr = msg.sender;
        fee = feeRate;
        interest = interestRate;
    }

    function stake(uint256 amount, uint timeInMinutes) public payable {
        require(amount != 0, "You cannot stake 0 tokens");
        s_balances[msg.sender] = s_balances[msg.sender] + amount;
        s_totalSupply += amount;
        // Probably not the best solution
        if (bytes32(stakersIndexes[msg.sender]) == "0x0000000000000000000000000000000000000000000000000000000000000000") {
            Staker storage newStaker;
            stakersIndexes[msg.sender] = index;
            newStaker.stakerAddr = msg.sender;
            newStaker.amountStaked = amount;
            newStaker.stakePeriod = timeInMinutes;
            newStaker.depositStartTime = block.timestamp;
            newStaker.depositFinishTime = block.timestamp + timeInMinutes * 60;
            newStaker.hasStaked = true;
            newStaker.index = index;
            index++;
            stakersList.push(newStaker);
        } else {
            uint currentIndex = stakersIndexes[msg.sender];
            Staker storage existingStaker = stakersList[currentIndex];
            require(existingStaker.hasStaked == false, 'You have already staked');
            Staker storage existingStakerInList = stakersList[existingStaker.index];
            existingStakerInList.amountStaked = amount;
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

    function stakeFor3minutes(uint256 amount) public {
        stake(amount, 3);
    }

    function stakeFor5minutes(uint256 amount) public {
        stake(amount, 5);
    }

    function stakeFor10minutes(uint256 amount) public {
        stake(amount, 10);
    }

    function unstakeAndClaimReward(uint256 amount) public {
        uint currentIndex = stakersIndexes[msg.sender];
        Staker storage existingStaker = stakersList[currentIndex];
        require(existingStaker.depositFinishTime < block.timestamp, "Your stake has not finished yet");
        uint rewardRaw = (existingStaker.amountStaked / 100) * interest * existingStaker.stakePeriod;
        uint rewardFinal = rewardRaw - (rewardRaw / 100) * fee;
        uint stakerAmount = existingStaker.amountStaked;

        existingStaker.amountStaked = 0;
        existingStaker.stakePeriod = 0;
        existingStaker.depositStartTime = 0;
        existingStaker.depositFinishTime = 0;
        existingStaker.hasStaked = false;

        s_balances[msg.sender] = s_balances[msg.sender] - amount;

        // bool success = trxToken.transfer(msg.sender, stakerAmount + rewardFinal);
        // if(!success) {
        //     revert Staking__TransferFailed();
        // }

        return rewardFinal;
    }

    function claimReward() public {
        Staker storage existingStaker = stakersMap[msg.sender];
        existingStaker.hasStaked = false;
        Staker storage existingStakerInList = stakersList[existingStaker.index];
        existingStakerInList.hasStaked = false;


    }
    
    function getStakers() public view returns(Staker[] memory) {
        return stakersList;
        
    }

    // function getTotalBalance() {
    //     return s_totalSupply;
    // }
}