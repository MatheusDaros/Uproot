const Migrations = artifacts.require("ERC20");

require('dotenv').config();

var Web3 = require('web3');

const totalSupply = 10000000;
const name = "Dai";
const symbol = "DAI";
const decimals = 18;

module.exports = function(deployer) {
    deployer.deploy(Migrations, name, symbol);
};