const Migrations = artifacts.require("StudentApplication");

require('dotenv').config();

//TODO library and require
function getAddress(file) {
    let input = require(file);
    let dKey = Object.keys(input.networks)[0];
    return input.networks[dKey].address;
}

var Web3 = require('web3');

const studentAddress = "0x923FA4819cC4A05b1E35de6272e39D051cf2AA9D";
const classroomAddress = getAddress('../build/contracts/Classroom.json');
const daiAddress = getAddress('../build/contracts/ERC20.json');
const challengeAddress = getAddress('../build/contracts/ExampleChallenge.json');
const seed = Web3.utils.asciiToHex(process.env.SEED);

module.exports = function(deployer) {
    deployer.deploy(Migrations, studentAddress, classroomAddress, challengeAddress, daiAddress, seed);
};