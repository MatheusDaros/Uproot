pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./gambi/BaseRelayRecipient.sol";
import "./gambi/GSNTypes.sol";
import "./gambi/IRelayHub.sol";
import "./interface/IClassroom.sol";
import "./interface/IStudent.sol";
import "./interface/IStudentApplication.sol";
import "./interface/IClassroomFactory.sol";
import "./interface/IStudentFactory.sol";
import "./interface/IStudentApplicationFactory.sol";
import "./interface/IUniversity.sol";
import "./interface/IGrantsManager.sol";
import "./MyUtils.sol";

//TODO: Natspec Document ENVERYTHING
//TODO: Sort function order from all contracts

contract University is Ownable, AccessControl, BaseRelayRecipient, IUniversity {
    using SafeMath for uint256;

    //CLASSLIST_ADMIN_ROLE can add new manually created classes to the list
    bytes32 public constant CLASSLIST_ADMIN_ROLE = keccak256(
        "CLASSLIST_ADMIN_ROLE"
    );
    // FUNDS_MANAGER_ROLE can withdraw funds from the contract
    bytes32 public constant FUNDS_MANAGER_ROLE = keccak256(
        "FUNDS_MANAGER_ROLE"
    );
    // GRANTS_MANAGER_ROLE can approve/decline grant claims
    bytes32 public constant GRANTS_MANAGER_ROLE = keccak256(
        "GRANTS_MANAGER_ROLE"
    );
    // READ_STUDENT_LIST_ROLE allow reading students list
    bytes32 public constant READ_STUDENT_LIST_ROLE = keccak256(
        "READ_STUDENT_LIST_ROLE"
    );
    /// STUDENT_IDENTITY_ROLE allow asking for grants and requesting a classroom from a successful application
    bytes32 public constant STUDENT_IDENTITY_ROLE = keccak256(
        "STUDENT_IDENTITY_ROLE"
    );
    /// CLASSROOM_PROFESSOR_ROLE can manage itself inside the University and registering student applications
    bytes32 public constant CLASSROOM_PROFESSOR_ROLE = keccak256(
        "CLASSROOM_PROFESSOR_ROLE"
    );
    /// UNIVERSITY_OVERSEER_ROLE can inspect Grant Managers and Fund Managers, and present cases for funders to vote upon
    bytes32 public constant UNIVERSITY_OVERSEER_ROLE = keccak256(
        "UNIVERSITY_OVERSEER_ROLE"
    );

    // Parameter: Name of this University
    bytes32 public name;
    // Parameter: University cut from professor (Parts per Million)
    uint24 public override cut;
    // List of every registered classroom
    address[] public _classList;
    // List of every student
    address[] _students;
    // Mapping of each student's applications
    mapping(address => address[]) _studentApplicationsMapping;
    // Address list of every donor
    address[] _donors;
    // GSN funds to give students
    uint256 _studentGSNDeposit;

    //TODO: resolve students and classrooms addresses using ENS

    CERC20 public cToken;
    IERC20 public daiToken;
    IRelayHub public relayHub;
    IClassroomFactory _classroomFactory;
    IStudentFactory _studentFactory;
    address _studentApplicationFactoryAddress;

    constructor(
        bytes32 _name,
        uint24 _cut,
        uint256 studentGSNDeposit,
        address daiAddress,
        address compoundAddress,
        address relayHubAddress,
        address classroomFactoryAddress,
        address studentFactoryAddress,
        address studentApplicationFactoryAddress
    ) public {
        name = _name;
        cut = _cut;
        _studentGSNDeposit = studentGSNDeposit;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(READ_STUDENT_LIST_ROLE, _msgSender());
        daiToken = IERC20(daiAddress);
        cToken = CERC20(compoundAddress);
        relayHub = IRelayHub(relayHubAddress);
        _classroomFactory = IClassroomFactory(classroomFactoryAddress);
        _studentFactory = IStudentFactory(studentFactoryAddress);
        _studentApplicationFactoryAddress = studentApplicationFactoryAddress;
    }

    receive() external payable {
        emit LogReceived(msg.sender, msg.value);
    }

    event LogNewClassroom(bytes32, address);
    event LogChangeName(bytes32);
    event LogChangeCut(uint24);
    event LogReceived(address, uint256);

    function changeName(bytes32 val) public onlyOwner {
        name = val;
        emit LogChangeName(name);
    }

    function changeCut(uint24 val) public onlyOwner {
        cut = val;
        emit LogChangeCut(cut);
    }

    function changeStudentGSNDeposit(uint256 val) public onlyOwner {
        _studentGSNDeposit = val;
    }

    function isValidClassroom(address classroom) public view override returns (bool) {
        return hasRole(CLASSROOM_PROFESSOR_ROLE, classroom);
    }

    function studentIsRegistered(address student) public view override returns (bool) {
        require(
            hasRole(READ_STUDENT_LIST_ROLE, _msgSender()),
            "University: caller doesn't have READ_STUDENT_LIST_ROLE"
        );
        return hasRole(STUDENT_IDENTITY_ROLE, student);
    }

    function viewMyApplications() public view override returns (address[] memory) {
        return viewStudentApplications(_msgSender());
    }

    function viewStudentApplications(address addr)
        public
        view
        override
        returns (address[] memory)
    {
        require(
            addr == _msgSender() || hasRole(GRANTS_MANAGER_ROLE, _msgSender()),
            "Classroom: read permission denied"
        );
        return _studentApplicationsMapping[addr];
    }

    function studentSelfRegisterGSN(bytes32 sName) public returns (address) {
        address student = _newStudent(sName, _msgSenderGSN());
        relayHub.depositFor.value(_studentGSNDeposit)(student);
        return student;
    }

    function studentSelfRegister(bytes32 sName) public returns (address) {
        return _newStudent(sName, _msgSender());
    }

    function _newStudent(bytes32 sName, address caller)
        internal
        returns (address)
    {
        require(
            _studentApplicationsMapping[_msgSenderGSN()].length == 0,
            "University: student already registered"
        );
        //Gambiarra: Push address(0) in the mapping to mark that student as registered in the university
        _studentApplicationsMapping[caller].push(address(0));
        address student = _studentFactory.newStudent(sName, address(this));
        IStudent(student).transferOwnershipStudent(caller);
        address studentAddr = address(student);
        _students.push(studentAddr);
        grantRole(STUDENT_IDENTITY_ROLE, studentAddr);
        return address(studentAddr);
    }

    //ex: owner, name, 0.2 * 10**6, 0.5 * 10**6, 0, 50 * (10 ** 18), 30 days, challengeAddress
    function newClassRoom(
        address owner,
        bytes32 cName,
        uint24 cCut,
        uint24 cPCut,
        int32 minScore,
        uint256 entryPrice,
        uint256 duration,
        address challengeAddress
    ) public returns (address) {
        require(
            hasRole(CLASSLIST_ADMIN_ROLE, _msgSender()),
            "University: caller doesn't have CLASSLIST_ADMIN_ROLE"
        );
        return
            _newClassRoom(
                owner,
                cName,
                cCut,
                cPCut,
                minScore,
                entryPrice,
                duration,
                challengeAddress
            );
    }

    function _newClassRoom(
        address owner,
        bytes32 cName,
        uint24 cCut,
        uint24 cPCut,
        int32 minScore,
        uint256 entryPrice,
        uint256 duration,
        address challengeAddress
    ) internal returns (address) {
        address classroom = _classroomFactory.newClassroom(
            cName,
            cCut,
            cPCut,
            minScore,
            entryPrice,
            duration,
            payable (address(this)),
            challengeAddress,
            address(daiToken),
            address(cToken),
            _studentApplicationFactoryAddress
        );
        IClassroom(classroom).transferOwnershipClassroom(owner);
        address classroomAddr = address(classroom);
        _classList.push(classroomAddr);
        grantRole(READ_STUDENT_LIST_ROLE, classroomAddr);
        grantRole(CLASSROOM_PROFESSOR_ROLE, classroomAddr);
        emit LogNewClassroom(cName, classroomAddr);
        return classroomAddr;
    }

    function studentRequestClassroom(
        address applicationAddr,
        bytes32 cName,
        uint24 cCut,
        uint24 cPCut,
        int32 minScore,
        uint256 entryPrice,
        uint256 duration,
        address challenge
    ) public override returns (address) {
        require(
            hasRole(STUDENT_IDENTITY_ROLE, _msgSender()),
            "University: caller doesn't have STUDENT_IDENTITY_ROLE"
        );
        require(
            checkForStudentApplication(_msgSender(), applicationAddr),
            "University: caller is not student of this application"
        );
        IStudentApplication application = IStudentApplication(applicationAddr);
        require(
            application.applicationState() == 3,
            "University: application is not successful"
        );
        return
            _newClassRoom(
                IStudent(_msgSender()).ownerStudent(),
                cName,
                cCut,
                cPCut,
                minScore,
                entryPrice,
                duration,
                challenge
            );
    }

    function registerStudentApplication(address student, address application)
        public override
    {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        _studentApplicationsMapping[student].push(application);
    }

    function checkForStudentApplication(
        address studentAddress,
        address applicationAddress
    ) internal view returns (bool) {
        for (
            uint256 i = 0;
            i < _studentApplicationsMapping[studentAddress].length;
            i++
        ) {
            if (
                _studentApplicationsMapping[studentAddress][i] ==
                applicationAddress
            ) return true;
        }
        return false;
    }

    function addStudentScore(address student, int32 val) public override {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        IStudent(student).addScore(val);
    }

    function subStudentScore(address student, int32 val) public override {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        IStudent(student).subScore(val);
    }

    function applyFunds(uint256 val) public {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        daiToken.approve(address(cToken), val);
        cToken.mint(val);
    }

    function recoverFunds(uint256 val) public {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        cToken.redeemUnderlying(val);
    }

    function spendFunds(address to, uint256 val) public {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        daiToken.transfer(to, val);
    }

    function allowFunds(address to, uint256 val) public {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        daiToken.approve(to, val);
    }

    function giveGrant(address studentApplication) public override {
        require(
            hasRole(GRANTS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have GRANTS_MANAGER_ROLE"
        );
        IStudentApplication(studentApplication).payEntryPrice();
    }

    function viewAllStudentsFromGrantManager(
            address grantsManager
        ) public returns (address[] memory) {
        require(
            hasRole(UNIVERSITY_OVERSEER_ROLE, _msgSender()),
            "University: caller doesn't have UNIVERSITY_OVERSEER_ROLE"
        );
        return IGrantsManager(grantsManager).viewAllStudents();
    }

    function viewAllStudentGrantsFromGrantManager(
            address student, 
            address grantsManager
        ) public returns (uint256[] memory) {
        require(
            hasRole(UNIVERSITY_OVERSEER_ROLE, _msgSender()),
            "University: caller doesn't have UNIVERSITY_OVERSEER_ROLE"
        );
        return IGrantsManager(grantsManager).viewAllGrantsForStudent(student);
    }

    function acceptRelayedCall(
        GSNTypes.RelayRequest calldata relayRequest,
        bytes calldata,
        uint256
    ) external pure returns (bytes memory context) {
        require(
            MyUtils.readBytes4(relayRequest.encodedFunction, 0) ==
                this.studentSelfRegisterGSN.selector,
            "University: GSN not enabled for this function"
        );
        return abi.encode(relayRequest.target, 0);
    }

    function refillUniversityRelayer(uint256 val) public {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have STUDENT_IDENTITY_ROLE"
        );
        relayHub.depositFor.value(val)(address(this));
    }

    //TODO: Trade DAI for ETH in Uniswap

    //TODO: fund

    //TODO: manage grants governance

    //TODO: implement funds manager

    //TODO: implement funds manager governance
}
