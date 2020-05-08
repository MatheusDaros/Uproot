const { solidity, MockProvider, deployContract } = require('ethereum-waffle');
const { use, expect } = require('chai');
const { ethers } = require("@nomiclabs/buidler");
const University = require('../build/contracts/University.json');

use(solidity);
require('dotenv').config();

//TODO library and require
function getAddress(file) {
    let input = require(file);
    let dKey = Object.keys(input.networks)[0];
    return input.networks[dKey].address;
}

//University Params
const name = ethers.utils.formatBytes32String(process.env.UNIVERSITY_NAME);
const cut = process.env.UNIVERSITY_CUT;
const studentGSNDeposit = process.env.UNIVERSITY_GSNDEPOSIT;
const relayHubAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"; //getAddress('../build/contracts/CERC20.json');
const classroomFactoryAddress = getAddress('../build/contracts/ClassroomFactory.json');
const studentFactoryAddress = getAddress('../build/contracts/StudentFactory.json');
const studentApplicationFactoryAddress = getAddress('../build/contracts/StudentApplicationFactory.json');
const daiAddress = getAddress('../build/contracts/ERC20.json');
const cDaiAddress = getAddress('../build/contracts/ERC20.json');


describe('University smart contract', () => {
    const provider = new MockProvider();
    const [ownerAddress] = provider.getWallets();

    async function deployBefore() {
        const contract = await deployContract(ownerAddress, University, [name, cut, studentGSNDeposit, daiAddress, cDaiAddress, relayHubAddress, classroomFactoryAddress, studentFactoryAddress, studentApplicationFactoryAddress]);
        return contract;
    }

    it("must register name at deploy", async() => {
        const contract = await deployBefore();
        expect(await contract.name()).to.equal(name);
    });

    //    it('Student register success', async() => {
    //        const sName = "Flavio Neto";
    //        await contractInstance.studentSelfRegister(web3.utils.utf8ToHex(sName), { from: student1Address });
    //        const result = await contractInstance.studentIsRegistered(student1Address, { from: ownerAddress });
    //        assert.equal(result, true, 'wrong');
    //    });
});