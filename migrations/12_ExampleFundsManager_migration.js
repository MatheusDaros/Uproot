const Migrations = artifacts.require("ExampleFundsManager");

require('dotenv').config();

var Web3 = require('web3');

//TODO library and require
function getAddress(file) {
    let input = require(file);
    let dKey = Object.keys(input.networks)[0];
    return input.networks[dKey].address;
}

const universityAddress = getAddress('../build/contracts/University.json');

module.exports = function(deployer) {
    deployer.deploy(Migrations, universityAddress);
};