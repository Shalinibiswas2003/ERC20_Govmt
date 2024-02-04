var ERC = artifacts.require("./ERC.sol");

module.exports = function(deployer) {
    deployer.deploy(ERC, 10000);
};