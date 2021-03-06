const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('getTotalBalance', async function () {
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

    it('should correctly provide info on total supply', async function () {
        const stakeValue = ethers.utils.parseEther('5');
        await staking.connect(testUser1).stake({ value: stakeValue });

        expect(await staking.connect(testUser1).getTotalBalance()).to.equal(5);
    });
});
