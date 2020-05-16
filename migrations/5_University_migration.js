const Migrations = artifacts.require("University");

var Web3 = require('web3');

// Using Ropsten
const name = Web3.utils.asciiToHex("Tapioca University");
const cut = 0.2 * 1e6;
const studentGSNDeposit = web3.utils.toWei("1", "milli");
const relayHubAddress = "0xD216153c06E857cD7f72665E0aF1d7D82172F494"; //same on every network
const classroomFactoryAddress = "0xf1c868D57fbC615B35C285300da6f8cDA8a9661E";
const studentFactoryAddress = "0x55f41e137ABb4F3fA368937399499Bc600Feffa2";
const studentApplicationFactoryAddress = "0xd86d148A491652E1FBBac3A478fb0a31e78fD456";
const daiAddress = "0xad6d458402f60fd3bd25163575031acdce07538d";
const compoundAddress = "0x6ce27497a64fffb5517aa4aee908b1e7eb63b9ff";


module.exports = function(deployer) {
    deployer.deploy(Migrations, name, cut, studentGSNDeposit, daiAddress, compoundAddress, relayHubAddress, classroomFactoryAddress, studentFactoryAddress, studentApplicationFactoryAddress);
};