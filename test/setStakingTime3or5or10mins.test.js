const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('setStakingTime3or5or10mins', async function () {
    let owner, testUser1, testUser2;

    beforeEach(async function () {
        [owner, testUser1, testUser2] = await ethers.getSigners();

        const StakingContractFactory = await ethers.getContractFactory(
            'StakingTron',
            owner
        );
        const staking = await StakingContractFactory.deploy();
        await staking.deployed();

        await staking.connect(testUser1).stake({ value: STAKEVALUE });
    });

    it('should fail if not the owner uses this function', async function () {
        await expect(
            staking.connect(testUser1).setStakingTime3or5or10mins(3)
        ).to.be.revertedWith('Ownable: caller is not the owner');
    });

    it('should fail if a wrong number was given', async function () {
        await expect(
            staking.connect(owner).setStakingTime3or5or10mins(99)
        ).to.be.revertedWith('Time should be equal to 3/5/10 mins');
    });

    it('should successfully set a new staking time', async function () {
        let tx = await staking.connect(owner).setStakingTime3or5or10mins(5);
        await tx.wait();

        expect(tx).to.equal(5);
    });
});
