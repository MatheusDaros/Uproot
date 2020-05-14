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
const Build_ExampleGrantsManager = require("../build/contracts/ExampleGrantsManager.json");
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
const placeHolderAddress = "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6"; //Random address
const uniswapDAI = "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6";
const uniswapLINK = "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6";
const uniswapRouter = "0xD115BFFAbbdd893A6f7ceA402e7338643Ced44a6";

describe("Grant process checks", function() {
    var DAI_ERC20,
        DAI_CERC20,
        LINK,
        AaveProvider,
        AaveLendingPool,
        AaveLendingPoolCore,
        DAI_Aave,
        RelayHub,
        ClassroomFactory,
        StudentFactory,
        StudentApplicationFactory,
        University,
        Student1,
        StudentApplication1,
        ExampleChallenge,
        ExampleGrantsManager,
        Classroom,
        ownerAddress,
        student1,
        teacher1;

    describe("Deploy and save state", function() {
        it("must deploy everything well", async function() {
            [ownerAddress, student1, teacher1] = await ethers.getSigners();
            DAI_ERC20 = await deployMock(ownerAddress, Build_DAI_ERC20, [
                "DAI",
                "DAI",
            ]);
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
            ExampleGrantsManager = await deployContract(
                ownerAddress,
                Build_ExampleGrantsManager, [University.address]
            );
            await ExampleGrantsManager.deployed();
            let roleGrantManger = ethers.utils.solidityKeccak256(
                ["string"], ["GRANTS_MANAGER_ROLE"]
            );
            let roleReadList = ethers.utils.solidityKeccak256(
                ["string"], ["READ_STUDENT_LIST_ROLE"]
            );
            University.grantRole(roleGrantManger, ExampleGrantsManager.address);
            University.grantRole(roleReadList, ExampleGrantsManager.address);
            await University.connect(student1).studentSelfRegister(sName);
            let role = ethers.utils.solidityKeccak256(
                ["string"], ["STUDENT_IDENTITY_ROLE"]
            );
            let studentCount = await University.getRoleMemberCount(role);
            let studentAddress1 = await University.getRoleMember(
                role,
                studentCount - 1
            );
            Student1 = new ethers.Contract(
                studentAddress1,
                Build_Student.abi,
                ethers.provider
            );
            await Student1.deployed();
            AaveProvider = await deployMock(
                ownerAddress,
                require("../build/contracts/ILendingPoolAddressesProvider.json")
            );
            AaveLendingPoolCore = await deployMock(
                ownerAddress,
                require("../build/contracts/ILendingPoolCore.json")
            );
            AaveLendingPool = await deployMock(
                ownerAddress,
                require("../build/contracts/ILendingPool.json")
            );
            DAI_Aave = await deployMock(
                ownerAddress,
                require("../build/contracts/aToken.json")
            );
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
            await Classroom.connect(teacher1).configureUniswap(
                uniswapDAI,
                uniswapLINK,
                uniswapRouter
            );
            await AaveProvider.mock.getLendingPoolCore.returns(
                AaveLendingPoolCore.address
            );
            await AaveProvider.mock.getLendingPool.returns(AaveLendingPool.address);
            await AaveLendingPoolCore.mock.getReserveATokenAddress.returns(
                DAI_Aave.address
            );
            await Classroom.connect(teacher1).configureAave(AaveProvider.address);
            await Classroom.connect(teacher1).openApplications();
            await Student1.connect(student1).applyToClassroom(Classroom.address);
        });
    });

    describe("Student ask for grant", function() {
        it("must ask for a grant", async function() {
            expect(await Classroom.connect(teacher1).countNewApplications()).to.equal(
                1
            );
            expect(
                await Student1.connect(student1).viewMyApplicationState(
                    Classroom.address
                )
            ).to.equal(0);
            expect(
                (
                    await University.connect(student1).viewMyStudentApplications(
                        Student1.address
                    )
                ).length
            ).to.equal(1);
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
                Student1.connect(student1).requestGrant(
                    ExampleGrantsManager.address,
                    StudentApplication1.address
                )
            ).to.be.revertedWith("GrantsManager: Classroom price is too high");
            expect(
                ExampleGrantsManager.connect(student1).changeMaximumPrice(
                    ethers.utils.parseEther("250")
                )
            ).to.be.revertedWith("Ownable: caller is not the owner");
            await ExampleGrantsManager.connect(ownerAddress).changeMaximumPrice(
                ethers.utils.parseEther("250")
            );
            await ExampleGrantsManager.connect(ownerAddress).changeRequiredAvg(1);
            expect(
                Student1.connect(student1).requestGrant(
                    ExampleGrantsManager.address,
                    StudentApplication1.address
                )
            ).to.be.revertedWith("GrantsManager: Student doesn't meet the criterias");
            await ExampleGrantsManager.connect(ownerAddress).changeRequiredAvg(0);
            await DAI_ERC20.mock.balanceOf.returns(
                ethers.utils.parseEther("0")
            );
            expect(
                Student1.connect(student1).requestGrant(
                    ExampleGrantsManager.address,
                    StudentApplication1.address
                )
            ).to.be.revertedWith("University: not enough available funds");
            await DAI_ERC20.mock.balanceOf.returns(
                ethers.utils.parseEther("1000000")
            );
            await DAI_ERC20.mock.transferFrom.returns(true);
            await Student1.connect(student1).requestGrant(
                ExampleGrantsManager.address,
                StudentApplication1.address
            );
            expect(
                await Student1.connect(student1).viewMyApplicationState(
                    Classroom.address
                )
            ).to.equal(1);
        });
    });
});