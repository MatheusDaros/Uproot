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
const { expect } = require("chai");
const { ethers } = require("@nomiclabs/buidler");

async function deployContract(signer, factory, params = []) {
    const MyContract = await ethers.getContractFactory(
        factory.abi,
        factory.bytecode,
        signer
    );
    const myContract = await MyContract.deploy(...params);
    await myContract.deployed();
    return myContract;
}

//University Params
const name = ethers.utils.formatBytes32String("Tapioca University");
const cut = 0.25 * 1e6;
const studentGSNDeposit = ethers.utils.parseEther("0.001");

//Student Params
const sName = ethers.utils.formatBytes32String("Flavio Neto");

//Classroom Params
const cName = ethers.utils.formatBytes32String("Tapiocaria");
const cCut = 0.25 * 1e6;
const cPCut = 0.5 * 1e6;
const minScore = 0;
const entryPrice = ethers.utils.parseEther("200");
const duration = 60 * 60 * 24 * 30;

describe("Class process Checks", function() {
    var DAI_ERC20,
        DAI_CERC20,
        RelayHub,
        ClassroomFactory,
        StudentFactory,
        StudentApplicationFactory,
        University,
        Student1,
        Student2,
        Student3,
        Student4,
        Student5,
        StudentT1,
        ExampleChallenge,
        Classroom,
        ownerAddress,
        student1,
        student2,
        student3,
        student4,
        student5,
        studentFake,
        teacher1,
        teacher2;

    var checkpointId;
    before(async function() {
        [
            ownerAddress,
            student1,
            student2,
            student3,
            student4,
            student5,
            studentFake,
            teacher1,
            teacher2,
        ] = await ethers.getSigners();
        DAI_ERC20 = await deployContract(ownerAddress, Build_DAI_ERC20, [
            "DAI",
            "DAI",
        ]);
        DAI_CERC20 = await deployContract(ownerAddress, Build_DAI_ERC20, [
            "CDAI",
            "CDAI",
        ]);
        RelayHub = await deployContract(ownerAddress, Build_RelayHub);
        ClassroomFactory = await deployContract(
            ownerAddress,
            Build_ClassroomFactory, []
        );
        StudentFactory = await deployContract(
            ownerAddress,
            Build_StudentFactory
        );
        StudentApplicationFactory = await deployContract(
            ownerAddress,
            Build_StudentApplicationFactory
        );
        University = await deployContract(ownerAddress, Build_University, [
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
        await University.connect(student1).studentSelfRegister(sName);
        await University.connect(student2).studentSelfRegister(sName);
        await University.connect(student3).studentSelfRegister(sName);
        await University.connect(student4).studentSelfRegister(sName);
        await University.connect(student5).studentSelfRegister(sName);
        const studentAddress_ = await University.connect(
            teacher1
        ).studentSelfRegister(sName);
        await studentAddress_.wait();
        let role = ethers.utils.solidityKeccak256(
            ["string"], ["STUDENT_IDENTITY_ROLE"]
        );
        let studentCount = await University.getRoleMemberCount(role);
        let studentAddress1 = await University.getRoleMember(
            role,
            studentCount - 6
        );
        let studentAddress2 = await University.getRoleMember(
            role,
            studentCount - 5
        );
        let studentAddress3 = await University.getRoleMember(
            role,
            studentCount - 4
        );
        let studentAddress4 = await University.getRoleMember(
            role,
            studentCount - 3
        );
        let studentAddress5 = await University.getRoleMember(
            role,
            studentCount - 2
        );
        let studentAddressT1 = await University.getRoleMember(
            role,
            studentCount - 1
        );
        Student1 = new ethers.Contract(
            studentAddress1,
            Build_Student.abi,
            ethers.provider
        );
        Student2 = new ethers.Contract(
            studentAddress2,
            Build_Student.abi,
            ethers.provider
        );
        Student3 = new ethers.Contract(
            studentAddress3,
            Build_Student.abi,
            ethers.provider
        );
        Student4 = new ethers.Contract(
            studentAddress4,
            Build_Student.abi,
            ethers.provider
        );
        Student5 = new ethers.Contract(
            studentAddress5,
            Build_Student.abi,
            ethers.provider
        );
        StudentT1 = new ethers.Contract(
            studentAddressT1,
            Build_Student.abi,
            ethers.provider
        );
        await StudentT1.deployed();
        ExampleChallenge = await deployContract(
            teacher1,
            Build_ExampleChallenge
        );
        const teacher1Address = await teacher1.getAddress();
        const ClassroomAddress_ = await University.connect(
            ownerAddress
        ).newClassRoom(
            teacher1Address,
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
        Classroom = new ethers.Contract(
            ClassroomAddress,
            Build_Classroom.abi,
            ethers.provider
        );
        await Classroom.deployed();
        checkpointId = await ethers.provider.send("evm_snapshot", []);
    });

    afterEach(async function() {
        await ethers.provider.send("evm_revert", [checkpointId]);
    });

    describe("Student apply fail", function() {
        it("must fail when registering to a wrong address", async function() {
            await expect(
                Student1.connect(student1).applyToClassroom(teacher1._address)
            ).to.be.revertedWith("Student: address is not a valid classroom");
        });
        it("must fail if professor self apply", async function() {
            await expect(
                StudentT1.connect(teacher1).applyToClassroom(Classroom.address)
            ).to.be.revertedWith("Classroom: professor can't be its own student");
        });
        it("must fail when registering before applications open", async function() {
            await expect(
                Student1.connect(student1).applyToClassroom(Classroom.address)
            ).to.be.revertedWith("VM Exception while processing transaction: revert Classroom: applications closed");
        });
        it("must fail if student score too low", async function() {
            await Classroom.connect(teacher1).changeMinScore(1);
            await expect(
                Student1.connect(student1).applyToClassroom(Classroom.address)
            ).to.be.reverted;
        });
    });

    describe("Class process", function() {
        it("must register name at deploy", async function() {
            expect(await University.name()).to.equal(name);
        });
    });
});