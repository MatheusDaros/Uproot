const Migrations = artifacts.require("Classroom");

require('dotenv').config();

//TODO library and require
function getAddress(file) {
    let input = require(file);
    let dKey = Object.keys(input.networks)[0];
    return input.networks[dKey].address;
}

var Web3 = require('web3');

const name = Web3.utils.asciiToHex(process.env.CLASSROOM_NAME);
const principalCut = Web3.utils.asciiToHex(process.env.CLASSROOM_PRINCIPAL_CUT);
const poolCut = Web3.utils.asciiToHex(process.env.CLASSROOM_POOL_CUT);
const minScore = Web3.utils.asciiToHex(process.env.CLASSROOM_MIN_SCORE);
const entryPrice = Web3.utils.asciiToHex(process.env.CLASSROOM_PRICE);
const duration = Web3.utils.asciiToHex(process.env.CLASSROOM_DURATION);
const universityAddress = getAddress('../build/contracts/University.json');
const challengeAddress = getAddress('../build/contracts/ExampleChallenge.json');
const daiAddress = getAddress('../build/contracts/ERC20.json');
const compoundAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F" //getAddress('../build/contracts/CERC20.json');
const studentApplicationFactoryAddress = getAddress('../build/contracts/StudentApplicationFactory.json');

module.exports = function(deployer) {
    deployer.deploy(Migrations, name, principalCut, poolCut, minScore, entryPrice, duration, universityAddress, challengeAddress, daiAddress, compoundAddress, studentApplicationFactoryAddress);
};