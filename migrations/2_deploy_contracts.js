var StakingTron = artifacts.require('./StakingTron.sol');

module.exports = function (deployer) {
    deployer.deploy(StakingTron, 3, 10);
};
