const Build_DAI_ERC20 = require("../build/contracts/ERC20.json");
const Build_DAI_CERC20 = require("../build/contracts/CERC20.json");
const Build_LINK = require("../build/contracts/LinkTokenInterface.json");
const Build_RelayHub = require("../build/contracts/BaseRelayRecipient.json");
const Build_ClassroomFactory = require("../build/contracts/ClassroomFactory.json");
const Build_Classroom = require("../build/contracts/Classroom.json");
const Build_StudentFactory = require("../build/contracts/StudentFactory.json");
const Build_Student = require("../build/contracts/Student.json");
const Build_StudentApplicationFactory = require("../build/contracts/studentApplicationFactory.json");
const Build_StudentApplication = require("../build/contracts/studentApplication.json");
const Build_University = require("../build/contracts/University.json");
const Build_ExampleChallenge = require("../build/contracts/ExampleChallenge.json");
const Build_ExampleFundsManager = require("../build/contracts/ExampleFundsManager.json");
const Build_ExampleGrantsManager = require("../build/contracts/ExampleGrantsManager.json");
const Build_ExampleStudentAnswer = require("../build/contracts/ExampleStudentAnswer.json");
const Build_ExampleWrongStudentAnswer = require("../build/contracts/ExampleWrongStudentAnswer.json");
const Build_UniversityFund = require("../build/contracts/UniversityFund.json");
const { expect } = require("chai");
const { ethers } = require("@nomiclabs/buidler");
const { deployMockContract } = require("@ethereum-waffle/mock-contract");

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

async function deployMock(signer, factory, params = []) {
    const myContract = await deployMockContract(signer, factory.abi);
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

//Contract Configurations - place the right values for each network
const oracleRandom = "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6";
const requestIdRandom = ethers.utils.formatBytes32String("REQUESTNUMBER");
const oraclePaymentRandom = ethers.utils.parseEther("1");
const oracleTimestamp = "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6";
const requestIdTimestamp = ethers.utils.formatBytes32String("REQUESTNUMBER");
const oraclePaymentTimestamp = ethers.utils.parseEther("1");
const linkToken = "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6";
const daiAddress = "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6"; //Random address
const compoundDAIAddress = "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6";
const comptrollerAddress = "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6";
const priceOracleAddress = "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6";
const uniswapWETH = "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6";
const uniswapDAI = "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6";
const uniswapLINK = "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6";
const uniswapRouter = "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6";
const lendingPoolAddressesProvider =
    "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6";

describe("Class process Checks", function() {
    var DAI_ERC20,
        DAI_CERC20,
        LINK,
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
        StudentApplication1,
        StudentApplication2,
        StudentApplication3,
        StudentApplication4,
        StudentApplication5,
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

    var baseCheckpointId;
    var courseCheckpointId;

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
        DAI_ERC20 = await deployMock(ownerAddress, Build_DAI_ERC20, ["DAI", "DAI"]);
        DAI_CERC20 = await deployMock(ownerAddress, Build_DAI_CERC20, [
            "CDAI",
            "CDAI",
        ]);
        LINK = await deployMock(ownerAddress, Build_LINK, ["LINK", "LINK"]);
        RelayHub = await deployMock(ownerAddress, Build_RelayHub);
        ClassroomFactory = await deployContract(
            ownerAddress,
            Build_ClassroomFactory, []
        );
        StudentFactory = await deployContract(ownerAddress, Build_StudentFactory);
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
        ExampleChallenge = await deployContract(teacher1, Build_ExampleChallenge);
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
        baseCheckpointId = await ethers.provider.send("evm_snapshot", []);
    });

    describe("Student apply fail", function() {
        it("must fail when registering to a wrong address", async function() {
            await expect(
                Student1.connect(student1).applyToClassroom(teacher1._address)
            ).to.be.revertedWith("Student: address is not a valid classroom");
            await ethers.provider.send("evm_revert", [baseCheckpointId]);
        });
        it("must fail if professor self apply", async function() {
            await expect(
                StudentT1.connect(teacher1).applyToClassroom(Classroom.address)
            ).to.be.revertedWith("Classroom: professor can't be its own student");
            await ethers.provider.send("evm_revert", [baseCheckpointId]);
        });
        it("must fail when registering before applications open", async function() {
            await expect(
                Student1.connect(student1).applyToClassroom(Classroom.address)
            ).to.be.revertedWith(
                "VM Exception while processing transaction: revert Classroom: applications closed"
            );
            await ethers.provider.send("evm_revert", [baseCheckpointId]);
        });
        it("must fail if student score too low", async function() {
            await Classroom.connect(teacher1).changeMinScore(1);
            await expect(
                Student1.connect(student1).applyToClassroom(Classroom.address)
            ).to.be.revertedWith("Classroom: student doesn't have enough score");
            await ethers.provider.send("evm_revert", [baseCheckpointId]);
        });
    });

    describe("Class process", function() {
        it("must open applications and begin course, saving state", async function() {
            await expect(
                Classroom.connect(teacher2).openApplications()
            ).to.be.revertedWith("Ownable: caller is not the owner");
            await expect(
                Classroom.connect(teacher1).openApplications()
            ).to.be.revertedWith("Classroom: setup oracles first");
            await LINK.mock.balanceOf.returns(ethers.utils.parseEther("1000000"));
            await Classroom.connect(teacher1).configureOracles(
                oracleRandom,
                requestIdRandom,
                oraclePaymentRandom,
                oracleTimestamp,
                requestIdTimestamp,
                oraclePaymentTimestamp,
                LINK.address,
                true
            );
            await expect(
                Classroom.connect(teacher1).openApplications()
            ).to.be.revertedWith("Classroom: setup Uniswap first");
            await Classroom.connect(teacher1).configureUniswap(
                uniswapDAI,
                uniswapLINK,
                uniswapRouter
            );
            await expect(
                Classroom.connect(teacher1).openApplications()
            ).to.be.revertedWith("Classroom: setup Aave first");
            await Classroom.connect(teacher1).configureAave(
                lendingPoolAddressesProvider,
                true
            );
            await LINK.mock.balanceOf.returns(ethers.utils.parseEther("0"));
            await expect(
                Classroom.connect(teacher1).openApplications()
            ).to.be.revertedWith("Classroom: not enough Link tokens");
            await LINK.mock.balanceOf.returns(ethers.utils.parseEther("1000000"));
            await expect(
                Classroom.connect(teacher1).closeApplications()
            ).to.be.revertedWith("Classroom: applications are already closed");
            await Classroom.connect(teacher1).openApplications();
            expect(await Classroom.openForApplication()).to.equal(true);
            await expect(
                Classroom.connect(teacher1).openApplications()
            ).to.be.revertedWith("Classroom: applications are already opened");
            await Classroom.connect(teacher1).closeApplications();
            expect(await Classroom.openForApplication()).to.equal(false);
            await Classroom.connect(teacher1).openApplications();
            expect(await Classroom.openForApplication()).to.equal(true);
            expect(await Classroom.isClassroomEmpty()).to.equal(true);
            expect(await Classroom.connect(teacher1).countNewApplications()).to.equal(
                0
            );
            await Student1.connect(student1).applyToClassroom(Classroom.address);
            expect(await Classroom.connect(teacher1).countNewApplications()).to.equal(
                1
            );
            expect(await Classroom.isClassroomEmpty()).to.equal(false);
            await Student2.connect(student2).applyToClassroom(Classroom.address);
            expect(await Classroom.connect(teacher1).countNewApplications()).to.equal(
                2
            );
            expect(await Classroom.isClassroomEmpty()).to.equal(false);
            expect(await Classroom.isCourseOngoing()).to.equal(false);
            expect(Classroom.connect(teacher1).beginCourse(true)).to.be.revertedWith(
                "Classroom: applications are still open"
            );
            await Classroom.connect(teacher1).closeApplications();
            expect(await Classroom.connect(teacher1).countNewApplications()).to.equal(
                2
            );
            expect(
                await Classroom.connect(teacher1).countReadyApplications()
            ).to.equal(0);
            await DAI_ERC20.mock.balanceOf
                .withArgs(Classroom.address)
                .returns(ethers.utils.parseEther("1000"));
            expect(Classroom.connect(teacher1).beginCourse(true)).to.be.revertedWith(
                "Classroom: invest all balance before begin"
            );
            expect(Classroom.connect(teacher1).finishCourse()).to.be.revertedWith(
                "Classroom: no applications"
            );
            expect(
                await Classroom.connect(teacher1).countReadyApplications()
            ).to.equal(0);
            expect(await Classroom.connect(teacher1).countNewApplications()).to.equal(
                2
            );
            await DAI_ERC20.mock.balanceOf
                .withArgs(Classroom.address)
                .returns(ethers.utils.parseEther("0"));
            await Classroom.connect(teacher1).beginCourse(true);
            expect(
                await Student1.connect(student1).viewMyApplicationState(
                    Classroom.address
                )
            ).to.equal(6);
            expect(await Classroom.connect(teacher1).countNewApplications()).to.equal(
                0
            );
            expect(await Classroom.isClassroomEmpty()).to.equal(true);
            await Classroom.connect(teacher1).openApplications();
            expect(await Classroom.openForApplication()).to.equal(true);
            await Student1.connect(student1).applyToClassroom(Classroom.address);
            expect(await Classroom.isClassroomEmpty()).to.equal(false);
            await Student2.connect(student2).applyToClassroom(Classroom.address);
            await Student3.connect(student3).applyToClassroom(Classroom.address);
            await Student4.connect(student4).applyToClassroom(Classroom.address);
            await Student5.connect(student5).applyToClassroom(Classroom.address);
            expect(await Classroom.connect(teacher1).countNewApplications()).to.equal(
                5
            );
            expect(
                await Classroom.connect(teacher1).countReadyApplications()
            ).to.equal(0);
            const studentApplicationAddress1 = await Student1.connect(
                student1
            ).viewMyApplication(Classroom.address);
            StudentApplication1 = new ethers.Contract(
                studentApplicationAddress1,
                Build_StudentApplication.abi,
                ethers.provider
            );
            await StudentApplication1.deployed();
            expect(
                await Student1.connect(student1).viewMyApplicationState(
                    Classroom.address
                )
            ).to.equal(0);
            const studentApplicationAddress2 = await Student2.connect(
                student2
            ).viewMyApplication(Classroom.address);
            StudentApplication2 = new ethers.Contract(
                studentApplicationAddress2,
                Build_StudentApplication.abi,
                ethers.provider
            );
            const studentApplicationAddress3 = await Student3.connect(
                student3
            ).viewMyApplication(Classroom.address);
            StudentApplication3 = new ethers.Contract(
                studentApplicationAddress3,
                Build_StudentApplication.abi,
                ethers.provider
            );
            const studentApplicationAddress4 = await Student4.connect(
                student4
            ).viewMyApplication(Classroom.address);
            StudentApplication4 = new ethers.Contract(
                studentApplicationAddress4,
                Build_StudentApplication.abi,
                ethers.provider
            );
            const studentApplicationAddress5 = await Student5.connect(
                student5
            ).viewMyApplication(Classroom.address);
            StudentApplication5 = new ethers.Contract(
                studentApplicationAddress5,
                Build_StudentApplication.abi,
                ethers.provider
            );
            await StudentApplication5.deployed();
            await DAI_ERC20.mock.balanceOf
                .withArgs(student1._address)
                .returns(ethers.utils.parseEther("0"));
            expect(
                StudentApplication1.connect(student1).payEntryPrice()
            ).to.be.revertedWith(
                "StudentApplication: sender can't pay the entry price"
            );
            await DAI_ERC20.mock.balanceOf
                .withArgs(student1._address)
                .returns(ethers.utils.parseEther("1000"));
            await DAI_ERC20.mock.balanceOf.returns(ethers.utils.parseEther("1000"));
            await DAI_ERC20.mock.transferFrom.returns(true);
            await StudentApplication1.connect(student1).payEntryPrice();
            expect(
                await Student1.connect(student1).viewMyApplicationState(
                    Classroom.address
                )
            ).to.equal(1);
            await StudentApplication2.connect(student2).payEntryPrice();
            expect(
                await Student2.connect(student2).viewMyApplicationState(
                    Classroom.address
                )
            ).to.equal(1);
            await StudentApplication3.connect(student3).payEntryPrice();
            await Classroom.connect(teacher1).closeApplications();
            expect(
                await Student3.connect(student3).viewMyApplicationState(
                    Classroom.address
                )
            ).to.equal(1);
            await StudentApplication4.connect(student4).payEntryPrice();
            expect(
                await Student4.connect(student4).viewMyApplicationState(
                    Classroom.address
                )
            ).to.equal(1);
            expect(
                await Student5.connect(student5).viewMyApplicationState(
                    Classroom.address
                )
            ).to.equal(0);
            await DAI_ERC20.mock.balanceOf
                .withArgs(Classroom.address)
                .returns(ethers.utils.parseEther("0"));
            await Classroom.connect(teacher1).beginCourse(true);
            expect(await Classroom.connect(teacher1).isCourseOngoing()).to.equal(
                true
            );
            expect(await Classroom.connect(student1).isCourseOngoing()).to.equal(
                true
            );
            courseCheckpointId = await ethers.provider.send("evm_snapshot", []);
        });

        it("must recover state, handle student answers", async function() {
            await ethers.provider.send("evm_revert", [courseCheckpointId]);
            expect(await Classroom.connect(teacher1).isCourseOngoing()).to.equal(
                true
            );
            expect(Classroom.connect(teacher1).beginCourse(true)).to.be.revertedWith(
                "Classroom: course already open"
            );
            expect(Classroom.connect(teacher1).beginCourse(true)).to.be.revertedWith(
                "Classroom: course already open"
            );
            expect(StudentApplication1.connect(student1).viewChallengeMaterial()).to.be.revertedWith(
                "StudentApplication: read permission denied"
            );
            expect(await Student1.connect(student1).viewChallengeMaterial(Classroom.address)).to.equal(
                "Material"
            );
            const Student1Answer = await deployContract(
                student1,
                Build_ExampleStudentAnswer, [StudentApplication1.address]
            );
            const Student2Answer = await deployContract(
                student2,
                Build_ExampleStudentAnswer, [StudentApplication2.address]
            );
            const Student3Answer = await deployContract(
                student3,
                Build_ExampleWrongStudentAnswer, [StudentApplication3.address]
            );
            const Student4Answer = await deployContract(
                student4,
                Build_ExampleWrongStudentAnswer, [StudentApplication1.address] //student trying to hack student1
            );
            await Student4Answer.deployed();

        });
    });
});