const Migrations = artifacts.require("ExampleStudentAnswer");

require('dotenv').config();

var Web3 = require('web3');

//TODO library and require
function getAddress(file) {
    let input = require(file);
    let dKey = Object.keys(input.networks)[0];
    return input.networks[dKey].address;
}

const application = "0x6B175474E89094C44Da98b954EedeAC495271d0F"; //getAddress('../build/contracts/StudentApplication.json');

module.exports = function(deployer) {
    deployer.deploy(Migrations, application);
};