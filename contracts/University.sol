pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Classroom.sol";
import "./Student.sol";
import "./StudentApplication.sol";

interface CERC20 {
    function mint(uint256) external returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function supplyRatePerBlock() external returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function getCash() external returns (uint);
    function balanceOfUnderlying(address account) external returns (uint);
}

contract University is Ownable, AccessControl {
    using SafeMath for uint256;

    //CLASSLIST_ADMIN_ROLE can add new manually created classes to the list
    bytes32 public constant CLASSLIST_ADMIN_ROLE = keccak256("CLASSLIST_ADMIN_ROLE");
    // FUNDS_MANAGER_ROLE can withdraw funds from the contract
    bytes32 public constant FUNDS_MANAGER_ROLE = keccak256("FUNDS_MANAGER_ROLE");
    // GRANTS_MANAGER_ROLE can approve/decline grant claims
    bytes32 public constant GRANTS_MANAGER_ROLE = keccak256("GRANTS_MANAGER_ROLE");
    // CLASSROOM_ROLE can manage itself inside the University and registering student applications
    bytes32 public constant CLASSROOM_ROLE = keccak256("CLASSROOM_ROLE");
    // READ_STUDENT_LIST_ROLE allow reading students list
    bytes32 public constant READ_STUDENT_LIST_ROLE = keccak256("READ_STUDENT_LIST_ROLE");
    // STUDENT_ROLE allow asking for grants and requesting a classroom from a successful application
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");

    // Parameter: Name of this University
    bytes32 _name;
    // Parameter: University cut from professor (Parts per Million)
    uint24 _cut;
    // List of every registered classroom
    Classroom[] _classList;
    // List of every student
    Student[] _students;
    // Mapping of each student's applications
    mapping(address => address[]) _studentApplicationsMapping;
    // Address list of every donor
    address[] _donors;

    CERC20 public cToken;
    IERC20 public daiToken;

    constructor(bytes32 name, uint24 cut, address daiAddress, address compoundAddress) public {
        _name = name;
        _cut = cut;
        _classList = new Classroom[](0);
        _students = new Student[](0);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(READ_STUDENT_LIST_ROLE, _msgSender());
        //Kovan address
        daiToken = IERC20(daiAddress);
        cToken = CERC20(compoundAddress);
    }

    event NewClassroom(bytes32 indexed name, address addr);

    function name() public view returns (bytes32){
        return _name;
    }

    function changeName(bytes32 val) public onlyOwner {
        _name = val;
    }

    function cut() public view returns (uint24){
        return _cut;
    }

    function changeCut(uint24 val) public onlyOwner {
        _cut = val;
    }

    function viewClassList() public view returns (Classroom[] memory) {
        return _classList;
    }

    function isValidClassroom(address classroom) public view returns (bool) {
        return hasRole(CLASSROOM_ROLE, classroom);
    }

    function newClassRoom(address owner, bytes32 cName) public {
         newClassRoom(owner, cName, 0.2 * 10**6, 0.5 * 10**6, 0, 50 * (10 ** 18), 30 days);
    }

    function newClassRoom(address owner, bytes32 cName, uint24 cCut, uint24 cPCut, int32 minScore, uint entryPrice, uint duration) public {
        require(hasRole(CLASSLIST_ADMIN_ROLE, _msgSender()), "University: caller doesn't have CLASSLIST_ADMIN_ROLE");
        _newClassRoom(owner, cName, cCut, cPCut, minScore, entryPrice, duration);
    }

    function _newClassRoom(address owner, bytes32 cName, uint24 cCut, uint24 cPCut, int32 minScore, uint entryPrice, uint duration) internal {
        //TODO: fetch contract from external factory to reduce size
        Classroom classroom = new Classroom(cName, cCut, cPCut, minScore, entryPrice, duration,
            address(this), address(daiToken), address(cToken));
        classroom.transferOwnership(owner);
        _classList.push(classroom);
        grantRole(READ_STUDENT_LIST_ROLE, address(classroom));
        grantRole(CLASSROOM_ROLE, address(classroom));
        emit NewClassroom(cName, address(classroom));
    }

    function studentSelfRegister(bytes32 sName) public {
        _newStudent(sName);
    }

    function _newStudent(bytes32 sName) internal {
        require(_studentApplicationsMapping[_msgSender()].length == 0, "University: student already registered");
        //Gambiarra: Push address(0) in the mapping to mark that student as registered in the university
        _studentApplicationsMapping[_msgSender()].push(address(0));
        //TODO: fetch contract from external factory to reduce size
        Student student = new Student(sName, address(this));
        student.transferOwnership(_msgSender());
        _students.push(student);
        grantRole(STUDENT_ROLE, address(student));
    }

    function studentIsRegistered(address student) public view returns (bool){
        require(hasRole(READ_STUDENT_LIST_ROLE, _msgSender()), "University: caller doesn't have READ_STUDENT_LIST_ROLE");
        return hasRole(STUDENT_ROLE, student);
    }

    function registerStudentApplication(address student, address application) public {
        require(hasRole(CLASSROOM_ROLE, _msgSender()), "University: caller doesn't have CLASSROOM_ROLE");
        _studentApplicationsMapping[student].push(application);
    }

    function viewMyApplications() public view returns (address[] memory) {
        return viewStudentApplications(_msgSender());
    }

    function viewStudentApplications(address addr) public view returns (address[] memory) {
        require(addr == _msgSender() || hasRole(GRANTS_MANAGER_ROLE, _msgSender()), "Classroom: read permission denied");
        return _studentApplicationsMapping[addr];
    }

    function studentRequestClassroom(address applicationAddr,
            bytes32 cName, uint24 cCut, uint24 cPCut, int32 minScore, uint entryPrice, uint duration) public {
        require(hasRole(STUDENT_ROLE, _msgSender()), "University: caller doesn't have STUDENT_ROLE");
        StudentApplication application = StudentApplication(applicationAddr);
        require(checkForStudentApplication(_msgSender(), applicationAddr), "University: caller is not student of this application");
        require(application.applicationState() == 3, "University: application is not successful");
        _newClassRoom(Student(_msgSender()).owner(), cName, cCut, cPCut, minScore, entryPrice, duration);
    }

    function checkForStudentApplication(address studentAddress, address applicationAddress) internal view returns (bool) {
        for (uint i = 0; i < _studentApplicationsMapping[studentAddress].length ; i++) {
            if (_studentApplicationsMapping[studentAddress][i] == applicationAddress) return true;
        }
        return false;
    }

    function addStudentScore(address student, int32 val) public  {
        require(hasRole(CLASSROOM_ROLE, _msgSender()), "University: caller doesn't have CLASSROOM_ROLE");
        Student(student).addScore(val);
    }

    function subStudentScore(address student,int32 val) public  {
        require(hasRole(CLASSROOM_ROLE, _msgSender()), "University: caller doesn't have CLASSROOM_ROLE");
        Student(student).subScore(val);
    }

    function applyFunds(uint val) public {
        require(hasRole(FUNDS_MANAGER_ROLE, _msgSender()), "University: caller doesn't have FUNDS_MANAGER_ROLE");
        daiToken.approve(address(cToken), val);
        cToken.mint(val);
    }

    function recoverFunds(uint val) public {
        require(hasRole(FUNDS_MANAGER_ROLE, _msgSender()), "University: caller doesn't have FUNDS_MANAGER_ROLE");
        cToken.redeemUnderlying(val);
    }

    function spendFunds(address to, uint val) public {
        require(hasRole(FUNDS_MANAGER_ROLE, _msgSender()), "University: caller doesn't have FUNDS_MANAGER_ROLE");
        daiToken.transfer(to, val);
    }

    function allowFunds(address to, uint val) public {
        require(hasRole(FUNDS_MANAGER_ROLE, _msgSender()), "University: caller doesn't have FUNDS_MANAGER_ROLE");
        daiToken.approve(to, val);
    }
}