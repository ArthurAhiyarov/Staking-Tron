// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();

contract StakingTron {

    IERC20 public trxToken;

    mapping(address => uint256) public s_balances;

    uint256 public s_totalSupply; // total staked balance
    uint public interest; // percent per munite
    uint public fee; 
    uint index = 0;
    address ownerAddr;

    struct Staker {
        address stakerAddr;
        uint amountStaked;
        uint depositStartTime;
        uint depositFinishTime;
        bool hasStaked;
        uint index;
    }

    Staker[] public stakersList;
    mapping(address => Staker) public stakersMap;

    constructor(address trxToken, uint feeRate, interestRate) {
        trxToken = IERC20(trxToken);
        ownerAddr = msg.sender;
        fee = feeRate;
        interest = interestRate;
    }

    function stake(uint256 amount, uint timeInMinutes) payable {
        require(amount != 0, "You cannot stake 0 tokens");
        s_balances[msg.sender] = s_balances[msg.sender] + amount;
        s_totalSupply += amount;
        if (stakersMap[msg.sender] = address(0x0)) {
            Staker storage newStaker = stakersMap[msg.sender];
            newStaker.stakerAddr = msg.sender;
            newStaker.amountStaked = amount;
            newStaker.depositStartTime = block.timestamp;
            newStaker.depositFinishTime = block.timestamp + timeInMinutes * 60;
            newStaker.hasStaked = true;
            newStaker.index = index;
            index++;
            stakersList.push(newStaker);
        } else {
            Staker storage existingStaker = stakersMap[msg.sender];
            require(existingStaker.hasStaked == false, 'You have already staked');
        }
        bool success = trxToken.transferFrom(msg.sender, address(this), amount);
        if(!success) {
            revert Staking__TransferFailed(); 
        }
    }

    function stakeFor3minutes(uint256 amount) {
        stake(amount, 3);
    }

    function stakeFor5minutes(uint256 amount) {
        stake(amount, 5);
    }

    function stakeFor10minutes(uint256 amount) {
        stake(amount, 10);
    }

    function unstake(uint256 amount) {

        s_balances[msg.sender] = s_balances[msg.sender] - amount;
        bool success = trxToken.transfer(msg.sender, amount);
        if(!success) {
            revert Staking__TransferFailed();
        }
    }

    function claimReward() {

    }
    
    function getStakers() {
        return stakersList;
        
    }

    function getTotalBalance() {
        return s_totalSupply;
    }
}