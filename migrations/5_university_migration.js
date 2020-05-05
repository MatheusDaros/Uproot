const Migrations = artifacts.require("University");

require('dotenv').config();

var Web3 = require('web3');

const name = Web3.utils.asciiToHex(process.env.UNIVERSITY_NAME);
const cut = Web3.utils.asciiToHex(process.env.UNIVERSITY_CUT);
const studentGSNDeposit = Web3.utils.asciiToHex(process.env.UNIVERSITY_GSNDEPOSIT);


const daiAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const compoundAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const relayHubAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const classroomFactoryAddress = getAddress('../build/contracts/ClassroomFactory.json');
const studentFactoryAddress = getAddress('../build/contracts/StudentFactory.json');
const studentApplicationFactoryAddress = getAddress('../build/contracts/StudentApplicationFactory.json');


module.exports = function(deployer) {
    deployer.deploy(Migrations, name, cut, studentGSNDeposit, daiAddress, compoundAddress, relayHubAddress, classroomFactoryAddress, studentFactoryAddress, studentApplicationFactoryAddress);
};

function getAddress(file) {
    let input = require(file);
    let dKey = Object.keys(input.networks)[0];
    return input.networks[dKey].address;
}