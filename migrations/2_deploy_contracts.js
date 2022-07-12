var StakingTron = artifacts.require('./StakingTron.sol');

module.exports = function (deployer) {
    deployer.deploy(StakingTron, 1, 1, 50, 50);
};
