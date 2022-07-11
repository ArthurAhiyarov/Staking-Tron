const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('unstakeAndClaimReward', async function () {
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

    it('should fail if the stake does not exist', async function () {
        await expect(
            staking.connect(testUser1).unstakeAndClaimReward()
        ).to.be.revertedWith('You have not staked');
    });

    it('should fail if the stake period has not finished yet', async function () {
        let stakeValue = ethers.utils.parseEther('5');
        await staking.connect(testUser1).stake({ value: stakeValue });

        await expect(
            staking.connect(testUser1).unstakeAndClaimReward(5)
        ).to.be.revertedWith('Your stake has not finished yet');
    });

    it('should fail if a user tries to unstake more that they have staked', async function () {
        let stakeValue = ethers.utils.parseEther('5');
        await staking.connect(testUser1).stake({ value: stakeValue });

        await expect(
            staking.connect(testUser1).unstakeAndClaimReward()
        ).to.be.revertedWith('Can not unstake that much');
    });
});
