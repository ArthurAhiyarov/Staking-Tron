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
            staking.connect(testUser1).setFeeRate(2)
        ).to.be.revertedWith('Ownable: caller is not the owner');
    });

    it('should fail if a new fee rate is bigger than the fee limit', async function () {
        await expect(staking.connect(owner).setFeeRate(51)).to.be.revertedWith(
            'Fee must be less than feeLimit'
        );
    });

    it('should successfully update and return a new fee rate', async function () {
        let tx = await staking.connect(owner).setFeeRate(49);
        await tx.wait();
        expect(tx).to.equal(49);
    });
});
