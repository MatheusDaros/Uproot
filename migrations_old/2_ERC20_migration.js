const Migrations = artifacts.require("ERC20");

require('dotenv').config();

var Web3 = require('web3');

const name = "Dai";
const symbol = "DAI";

module.exports = function(deployer) {
    deployer.deploy(Migrations, name, symbol);
};