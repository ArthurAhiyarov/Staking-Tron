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

    it('should fail if not the owner uses this function', async function () {
        await expect(
            staking.connect(testUser1).setInterestRate(2)
        ).to.be.revertedWith('Ownable: caller is not the owner');
    });

    it('should fail if a new interest rate is bigger than the interest limit', async function () {
        await expect(
            staking.connect(owner).setInterestRate(51)
        ).to.be.revertedWith('Interest must be less than interestLimit');
    });
    it('should successfully update and return a new interest rate', async function () {
        let tx = await staking.connect(owner).setInterestRate(49);
        await tx.wait();
        expect(tx).to.equal(49);
    });
});
