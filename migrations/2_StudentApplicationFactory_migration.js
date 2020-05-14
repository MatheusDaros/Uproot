const Migrations = artifacts.require("StudentApplicationFactory");

require('dotenv').config();

var Web3 = require('web3');

module.exports = function(deployer) {
    deployer.deploy(Migrations);
};