const { expect } = require('chai');
const { ethers } = require('hardhat');

async function getBlockTimeStamp(bn) {
    return (await ethers.provider.getBlock(bn)).timestamp;
}

describe('getStakers', async function () {
    let owner, testUser1, testUser1Addr;

    beforeEach(async function () {
        [owner, testUser1] = await ethers.getSigners();

        testUser1Addr = await testUser1.getAddress();

        const StakingContractFactory = await ethers.getContractFactory(
            'StakingTron',
            owner
        );
        const staking = await StakingContractFactory.deploy();
        await staking.deployed();
    });

    it('should correctly return the stakers info', async function () {
        const stakeValue = ethers.utils.parseEther('5');
        await staking.connect(testUser1).stake({ value: stakeValue });

        const stakePeriod = await staking.connect(owner).stakingTime();
        let info = await staking.connect(testUser1).getStakers();
        const blockTimeStamp = await getBlockTimeStamp(info.blockNumber);
        const stakerInfo = info[0];

        expect(stakerInfo.stakerAddr).to.equal(testUser1Addr);
        expect(stakerInfo.amountStaked).to.equal(stakeValue);
        expect(stakerInfo.stakePeriod).to.equal(stakePeriod);
        expect(stakerInfo.depositStartTime).to.equal(blockTimeStamp);
        expect(stakerInfo.depositFinishTime).to.equal(
            blockTimeStamp + stakePeriod * 60
        );
        expect(stakerInfo.hasStaked).to.equal(true);
        expect(stakerInfo.index).to.equal(0);
    });
});
