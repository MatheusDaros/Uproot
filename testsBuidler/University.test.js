const Build_DAI_ERC20 = require("../build/contracts/ERC20.json");
const Build_DAI_CERC20 = require("../build/contracts/CERC20.json");
const Build_RelayHub = require("../build/contracts/BaseRelayRecipient.json");
const Build_ClassroomFactory = require("../build/contracts/ClassroomFactory.json");
const Build_StudentFactory = require("../build/contracts/StudentFactory.json");
const Build_StudentApplicationFactory = require("../build/contracts/studentApplicationFactory.json");
const Build_University = require("../build/contracts/University.json");
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

//University Params
const name = ethers.utils.formatBytes32String(process.env.UNIVERSITY_NAME);
const cut = process.env.UNIVERSITY_CUT;
const studentGSNDeposit = process.env.UNIVERSITY_GSNDEPOSIT;

describe("University smart contract", () => {
    async function fixture(provider, [ownerAddress, student1]) {
        const DAI_ERC20 = await deployContract(ownerAddress, Build_DAI_ERC20, ["DAI", "DAI"]);
        const DAI_CERC20 = await deployContract(ownerAddress, Build_DAI_CERC20);
        const RelayHub = await deployContract(ownerAddress, Build_RelayHub);
        const ClassroomFactory = await deployContract(
            ownerAddress,
            Build_ClassroomFactory
        );
        const StudentFactory = await deployContract(
            ownerAddress,
            Build_StudentFactory
        );
        const StudentApplicationFactory = await deployContract(
            ownerAddress,
            Build_StudentApplicationFactory
        );
        const University = await deployContract(ownerAddress, Build_University, [
            name,
            cut,
            studentGSNDeposit,
            DAI_ERC20.address,
            DAI_CERC20.address,
            RelayHub.address,
            ClassroomFactory.address,
            StudentFactory.address,
            StudentApplicationFactory.address,
        ]);
        return {
            DAI_ERC20,
            DAI_CERC20,
            RelayHub,
            ClassroomFactory,
            StudentFactory,
            StudentApplicationFactory,
            University,
            ownerAddress,
            student1,
        };
    }

    describe("Deployment", function() {
        it("must register name at deploy", async() => {
            const {
                DAI_ERC20,
                DAI_CERC20,
                RelayHub,
                ClassroomFactory,
                StudentFactory,
                StudentApplicationFactory,
                University,
                ownerAddress,
                student1,
            } = await loadFixture(fixture);
            expect(await University.name()).to.equal(name);
        });

        it("must save owner at deploy", async() => {
            const {
                DAI_ERC20,
                DAI_CERC20,
                RelayHub,
                ClassroomFactory,
                StudentFactory,
                StudentApplicationFactory,
                University,
                ownerAddress,
                student1,
            } = await loadFixture(fixture);
            expect(await University.owner()).to.equal(ownerAddress.address);
        });

        it("must save DEFAULT ADMIN ROLE at deploy", async() => {
            const {
                DAI_ERC20,
                DAI_CERC20,
                RelayHub,
                ClassroomFactory,
                StudentFactory,
                StudentApplicationFactory,
                University,
                ownerAddress,
                student1,
            } = await loadFixture(fixture);
            const DEFAULT_ADMIN_ROLE =
                "0x0000000000000000000000000000000000000000000000000000000000000000";
            expect(
                await University.hasRole(DEFAULT_ADMIN_ROLE, ownerAddress.address)
            ).to.equal(true);
        });

        it("must save READ STUDENT LIST ROLE at deploy", async() => {
            const {
                DAI_ERC20,
                DAI_CERC20,
                RelayHub,
                ClassroomFactory,
                StudentFactory,
                StudentApplicationFactory,
                University,
                ownerAddress,
                student1,
            } = await loadFixture(fixture);
            const ROLE = ethers.utils.solidityKeccak256(
                ["string"], ["READ_STUDENT_LIST_ROLE"]
            );
            expect(await University.hasRole(ROLE, ownerAddress.address)).to.equal(
                true
            );
        });
    });

    describe("Change University Name", function() {
        it("Update University Name success", async() => {
            const {
                DAI_ERC20,
                DAI_CERC20,
                RelayHub,
                ClassroomFactory,
                StudentFactory,
                StudentApplicationFactory,
                University,
                ownerAddress,
                student1,
            } = await loadFixture(fixture);
            const newName = ethers.utils.formatBytes32String("Nova Tapioca");
            await University.changeName(newName);
            expect(await University.name()).to.equal(newName);
        });
    });

    describe("Student Register", function() {
        it("Student register success", async() => {
            const {
                DAI_ERC20,
                DAI_CERC20,
                RelayHub,
                ClassroomFactory,
                StudentFactory,
                StudentApplicationFactory,
                University,
                ownerAddress,
                student1,
            } = await loadFixture(fixture);
            const sName = ethers.utils.formatBytes32String("Flavio Neto");
            const studentContract = await University.connect(
                student1
            ).studentSelfRegister(sName);
            expect(await University.name()).to.equal(name);
            //await contractInstance.studentSelfRegister(web3.utils.utf8ToHex(sName), { from: student1Address });
            //const result = await contractInstance.studentIsRegistered(student1Address, { from: ownerAddress });
            //assert.equal(result, true, 'wrong');
        });
    });
});