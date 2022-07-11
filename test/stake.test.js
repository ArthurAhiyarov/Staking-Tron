const { expect } = require('chai');
const { ethers } = require('hardhat');

async function getBlockTimeStamp(bn) {
    return (await ethers.provider.getBlock(bn)).timestamp;
}

describe('stake', async function () {
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

    it('should fail if there is no payment', async function () {
        await expect(staking.connect(testUser1).stake()).to.be.revertedWith(
            'You cannot stake 0 tokens'
        );
    });

    it('should fail if 0 eth was sent', async function () {
        await expect(
            staking
                .connect(testUser1)
                .stake({ value: ethers.utils.parseEther('0') })
        ).to.be.revertedWith('You cannot stake 0 tokens');
    });

    it('should successfully a stake and emit the staked event', async function () {
        let stakeValue = ethers.utils.parseEther('5');
        let tx = await staking.connect(testUser1).stake({ value: stakeValue });
        await tx.wait();

        expect(tx)
            .to.emit(staking, 'staked')
            .withArgs(
                testUser1,
                stakeValue,
                await getBlockTimeStamp(tx.blockNumber)
            );
    });
});
