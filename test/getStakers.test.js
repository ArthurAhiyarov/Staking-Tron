const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('setInterestRate', async function () {
    let owner, testUser1, testUser2;

    beforeEach(async function () {
        [owner, testUser1, testUser2] = await ethers.getSigners();

        const StakingContractFactory = await ethers.getContractFactory(
            'StakingTron',
            owner
        );
        const staking = await StakingContractFactory.deploy();
        await staking.deployed();
    });
});
