const Migrations = artifacts.require("ExampleGrantsManager");

require('dotenv').config();

var Web3 = require('web3');

//TODO library and require
function getAddress(file) {
    let input = require(file);
    let dKey = Object.keys(input.networks)[0];
    return input.networks[dKey].address;
}

const universityAddress = "0x966EC4A36D14fA1E9472eC2bf88fb684E30F32FF"  //('../build/contracts/University.json');

module.exports = function(deployer) {
    deployer.deploy(Migrations, universityAddress);
};