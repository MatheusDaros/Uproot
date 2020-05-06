const Migrations = artifacts.require("University");

require('dotenv').config();

//TODO library and require
function getAddress(file) {
    let input = require(file);
    let dKey = Object.keys(input.networks)[0];
    return input.networks[dKey].address;
}

var Web3 = require('web3');

const studentAddress = accounts[1]
const classroomAddress = getAddress('../build/contracts/Classroom.json');
const daiAddress = getAddress('../build/contracts/ERC20.json');
const challengeAddress = getAddress('../build/contracts/ExampleChallenge.json');
const seed = Web3.utils.asciiToHex(process.env.SEED);

module.exports = function(deployer) {
    deployer.deploy(Migrations, studentAddress, classroomAddress, challengeAddress, daiAddress, seed);
};