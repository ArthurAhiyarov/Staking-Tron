const { expect } = require('chai');
const { ethers } = require('hardhat');

const STAKEVALUE = ethers.utils.parseEther('5');
const STAKEDURATION = 180; //in seconds

async function getBlockTimeStamp(bn) {
    return (await ethers.provider.getBlock(bn)).timestamp;
}

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

        await staking.connect(testUser1).stake({ value: STAKEVALUE });
    });

    it('should fail if the stake does not exist', async function () {
        await expect(
            staking.connect(testUser2).unstakeAndClaimReward()
        ).to.be.revertedWith('You have not staked');
    });

    it('should fail if the stake period has not finished yet', async function () {
        await staking.connect(testUser1).stake({ value: STAKEVALUE });

        await expect(
            staking.connect(testUser1).unstakeAndClaimReward(STAKEVALUE)
        ).to.be.revertedWith('Your stake has not finished yet');
    });

    it('should fail if a user tries to unstake more that they have staked', async function () {
        await expect(
            staking.connect(testUser1).unstakeAndClaimReward(STAKEVALUE + 1)
        ).to.be.revertedWith('Can not unstake that much');
    });

    it('should successfully unstake and emit the unstaked event', async function () {
        await ethers.provider.send('evm_mine', [
            (await getBlockTimeStamp(voting.blockNumber)) + STAKEDURATION + 1,
        ]);

        let tx = await staking
            .connect(testUser1)
            .unstakeAndClaimReward(STAKEVALUE);

        await tx.wait();

        expect(tx)
            .to.emit(staking, 'unstaked')
            .withArgs(
                testUser1,
                STAKEVALUE,
                await getBlockTimeStamp(tx.blockNumber)
            );

        let interest = await staking.connect(owner).interest();
        let stakePeriod = await staking.connect(owner).stakingTime();
        let fee = await staking.connect(owner).fee();
        let rewardRaw = (STAKEVALUE / 100) * interest * stakePeriod;
        let ownerFee = (rewardRaw / 100) * fee;
        let rewardFinal = rewardRaw - ownerFee;

        expect(tx).to.equal(rewardFinal);
    });
});
