const {
    solidity,
    MockProvider,
    deployContract,
    loadFixture,
} = require("ethereum-waffle");
const { use, expect } = require("chai");
const { ethers } = require("@nomiclabs/buidler");

use(solidity);
require("dotenv").config();

//TODO library and require
function getAddress(file) {
    return "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    //let input = require(file);
    //let dKey = Object.keys(input.networks)[0];
    //return input.networks[dKey].address;
}

//University Params
const name = ethers.utils.formatBytes32String(process.env.UNIVERSITY_NAME);
const cut = process.env.UNIVERSITY_CUT;
const studentGSNDeposit = process.env.UNIVERSITY_GSNDEPOSIT;
const relayHubAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"; //getAddress('../build/contracts/CERC20.json');
const classroomFactoryAddress = getAddress(
    "../build/contracts/ClassroomFactory.json"
);
const studentFactoryAddress = getAddress(
    "../build/contracts/StudentFactory.json"
);
const studentApplicationFactoryAddress = getAddress(
    "../build/contracts/StudentApplicationFactory.json"
);
const daiAddress = getAddress("../build/contracts/ERC20.json");
const cDaiAddress = getAddress("../build/contracts/ERC20.json");

describe("University smart contract", () => {
    let CFactory;
    let contract;
    let ownerAddress;
    let student1;

    beforeEach(async function() {
        CFactory = await ethers.getContractFactory("University");
        [ownerAddress, student1] = await ethers.getSigners();
        contract = await CFactory.deploy(
            name,
            cut,
            studentGSNDeposit,
            daiAddress,
            cDaiAddress,
            relayHubAddress,
            classroomFactoryAddress,
            studentFactoryAddress,
            studentApplicationFactoryAddress
        );
        await contract.deployed();
    });

    describe("Deployment", function() {
        it("must register name at deploy", async() => {
            expect(await contract.name()).to.equal(name);
        });

        it("must save owner at deploy", async() => {
            expect(await contract.owner()).to.equal(ownerAddress._address);
        });

        it("must save DEFAULT ADMIN ROLE at deploy", async() => {
            const DEFAULT_ADMIN_ROLE =
                "0x0000000000000000000000000000000000000000000000000000000000000000";
            expect(
                await contract.hasRole(DEFAULT_ADMIN_ROLE, ownerAddress._address)
            ).to.equal(true);
        });

        it("must save READ STUDENT LIST ROLE at deploy", async() => {
            const ROLE = ethers.utils.solidityKeccak256(
                ["string"], ["READ_STUDENT_LIST_ROLE"]
            );
            expect(await contract.hasRole(ROLE, ownerAddress._address)).to.equal(
                true
            );
        });
    });

    describe("Change University Name", function() {
        it("Update University Name success", async() => {
            const newName = ethers.utils.formatBytes32String("Nova Tapioca");
            await contract.changeName(newName);
            expect(await contract.name()).to.equal(newName);
        });
    });

    describe("Student Register", function() {
        it("Student register success", async() => {
            const sName = ethers.utils.formatBytes32String("Flavio Neto");
            const studentContract = await contract
                .connect(student1)
                .studentSelfRegister(sName);
            expect(await contract.name()).to.equal(name);
            //await contractInstance.studentSelfRegister(web3.utils.utf8ToHex(sName), { from: student1Address });
            //const result = await contractInstance.studentIsRegistered(student1Address, { from: ownerAddress });
            //assert.equal(result, true, 'wrong');
        });
    });
});