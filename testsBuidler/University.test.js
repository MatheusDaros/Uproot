const Build_DAI_ERC20 = require("../build/contracts/ERC20.json");
const Build_DAI_CERC20 = require("../build/contracts/CERC20.json");
const Build_RelayHub = require("../build/contracts/BaseRelayRecipient.json");
const Build_ClassroomFactory = require("../build/contracts/ClassroomFactory.json");
const Build_Classroom = require("../build/contracts/Classroom.json");
const Build_StudentFactory = require("../build/contracts/StudentFactory.json");
const Build_Student = require("../build/contracts/Student.json");
const Build_StudentApplicationFactory = require("../build/contracts/studentApplicationFactory.json");
const Build_University = require("../build/contracts/University.json");
const Build_ExampleChallenge = require("../build/contracts/ExampleChallenge.json");
const Build_ExampleFundsManager = require("../build/contracts/ExampleFundsManager.json");
const Build_ExampleGrantsManager = require("../build/contracts/ExampleGrantsManager.json");
const Build_ExampleStudentAnswer = require("../build/contracts/ExampleStudentAnswer.json");
const Build_ExampleWrongStudentAnswer = require("../build/contracts/ExampleWrongStudentAnswer.json");
const Build_UniversityFund = require("../build/contracts/UniversityFund.json");
const { solidity, deployContract, loadFixture } = require("ethereum-waffle");
const { use, expect } = require("chai");
const { ethers } = require("@nomiclabs/buidler");

use(solidity);
require("dotenv").config();

//University Params
const name = ethers.utils.formatBytes32String(process.env.UNIVERSITY_NAME);
const cut = process.env.UNIVERSITY_CUT;
const studentGSNDeposit = process.env.UNIVERSITY_GSNDEPOSIT;

//Student Params
const sName = ethers.utils.formatBytes32String("Flavio Neto");

//Classroom Params
const cName = ethers.utils.formatBytes32String("Tapiocaria");
const cCut = 0.25 * 1e6;
const cPCut = 0.5 * 1e6;
const minScore = 0;
const entryPrice = ethers.utils.parseEther("200");
const duration = 60 * 60 * 24 * 30;

describe("Basic Checks", function() {
    async function fixture(
        provider, [
            ownerAddress,
            student1,
            student2,
            teacher1,
            teacher2,
        ]
    ) {
        const DAI_ERC20 = await deployContract(ownerAddress, Build_DAI_ERC20, [
            "DAI",
            "DAI",
        ]);
        const DAI_CERC20 = await deployContract(ownerAddress, Build_DAI_CERC20);
        const RelayHub = await deployContract(ownerAddress, Build_RelayHub);
        const ClassroomFactory = await deployContract(
            ownerAddress,
            Build_ClassroomFactory, [], {
                gasLimit: 6000000
            }
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
        await University.deployed();
        const studentAddress_ = await University.connect(
            student1
        ).studentSelfRegister(sName);
        await studentAddress_.wait();
        let role = ethers.utils.solidityKeccak256(
            ["string"], ["STUDENT_IDENTITY_ROLE"]
        );
        let studentCount = await University.getRoleMemberCount(role);
        let studentAddress = await University.getRoleMember(role, studentCount - 1);
        const Student = new ethers.Contract(
            studentAddress,
            Build_Student.abi,
            provider
        );
        await Student.deployed();
        const ExampleChallenge = await deployContract(
            teacher1,
            Build_ExampleChallenge
        );
        const ClassroomAddress_ = await University.connect(
            ownerAddress
        ).newClassRoom(
            teacher1.address,
            cName,
            cCut,
            cPCut,
            minScore,
            entryPrice,
            duration,
            ExampleChallenge.address
        );
        await ClassroomAddress_.wait();
        let role2 = ethers.utils.solidityKeccak256(
            ["string"], ["CLASSROOM_PROFESSOR_ROLE"]
        );
        let classroomCount = await University.getRoleMemberCount(role2);
        let ClassroomAddress = await University.getRoleMember(
            role2,
            classroomCount - 1
        );
        const Classroom = new ethers.Contract(
            ClassroomAddress,
            Build_Classroom.abi,
            provider
        );
        await Classroom.deployed();
        const ExampleGrantsManager = await deployContract(
            ownerAddress,
            Build_ExampleGrantsManager, [University.address]
        );
        return {
            DAI_ERC20,
            DAI_CERC20,
            RelayHub,
            ClassroomFactory,
            StudentFactory,
            StudentApplicationFactory,
            University,
            Student,
            ExampleChallenge,
            Classroom,
            ExampleGrantsManager,
            ownerAddress,
            student1,
            student2,
            teacher1,
            teacher2,
        };
    }

    describe("Deployment", function() {
        it("must register name at deploy", async function() {
            const { University } = await loadFixture(fixture);
            expect(await University.name()).to.equal(name);
        });

        it("must save owner at deploy", async function() {
            const { University, ownerAddress } = await loadFixture(fixture);
            expect(await University.owner()).to.equal(ownerAddress.address);
        });

        it("must save DEFAULT ADMIN ROLE at deploy", async function() {
            const { University, ownerAddress } = await loadFixture(fixture);
            const DEFAULT_ADMIN_ROLE =
                "0x0000000000000000000000000000000000000000000000000000000000000000";
            expect(
                await University.hasRole(DEFAULT_ADMIN_ROLE, ownerAddress.address)
            ).to.equal(true);
        });

        it("must save READ STUDENT LIST ROLE at deploy", async function() {
            const { University, ownerAddress } = await loadFixture(fixture);
            const ROLE = ethers.utils.solidityKeccak256(
                ["string"], ["READ_STUDENT_LIST_ROLE"]
            );
            expect(await University.hasRole(ROLE, ownerAddress.address)).to.equal(
                true
            );
        });
    });

    describe("Change University Params", function() {
        it("Update University Name success", async function() {
            const { University } = await loadFixture(fixture);
            const newVal = ethers.utils.formatBytes32String("Nova Tapioca");
            await University.changeName(newVal);
            expect(await University.name()).to.equal(newVal);
        });
        it("Update University Name revert", async function() {
            const { University, student1 } = await loadFixture(fixture);
            const newVal = ethers.utils.formatBytes32String("Nova Tapioca");
            await expect(University.connect(student1).changeName(newVal)).to.be
                .reverted;
        });
        it("Update University Cut success", async function() {
            const { University } = await loadFixture(fixture);
            const newVal = 0;
            await University.changeCut(newVal);
            expect(await University.cut()).to.equal(newVal);
        });
        it("Update University Cut revert", async function() {
            const { University, student1 } = await loadFixture(fixture);
            const newVal = 0;
            await expect(University.connect(student1).changeCut(newVal)).to.be
                .reverted;
        });
    });

    describe("Student Register", function() {
        it("Student register success", async function() {
            const { Student } = await loadFixture(fixture);
            expect(await Student.name()).to.equal(sName);
        });
        it("Student register revert", async function() {
            const { University, student1 } = await loadFixture(fixture);
            const sName = ethers.utils.formatBytes32String("Flavio Clone");
            await expect(University.connect(student1).studentSelfRegister(sName)).to
                .be.reverted;
        });
    });

    describe("Student Change Params", function() {
        it("Student change name success", async function() {
            const { Student, student1 } = await loadFixture(fixture);
            const newVal = ethers.utils.formatBytes32String("Ronaldo");
            await Student.connect(student1).changeName(newVal);
            expect(await Student.name()).to.equal(newVal);
        });
        it("Student change name revert", async function() {
            const { Student, ownerAddress } = await loadFixture(fixture);
            const newVal = ethers.utils.formatBytes32String("Ronaldo");
            await expect(Student.connect(ownerAddress).changeName(newVal)).to.be
                .reverted;
        });
    });

    describe("Student Cheating", function() {
        it("Student change score revert", async function() {
            const { Student, student1 } = await loadFixture(fixture);
            await expect(Student.connect(student1).addScore(1)).to.be.reverted;
        });
    });

    describe("Classroom Register", function() {
        it("Student register success", async function() {
            const { Classroom } = await loadFixture(fixture);
            expect(await Classroom.name()).to.equal(cName);
        });
        it("Classroom register revert", async function() {
            const { University, ExampleChallenge, student2 } = await loadFixture(
                fixture
            );
            await expect(
                University.connect(student2).newClassRoom(
                    student2.address,
                    cName,
                    cCut,
                    cPCut,
                    minScore,
                    entryPrice,
                    duration,
                    ExampleChallenge.address
                )
            ).to.be.reverted;
        });
    });
});