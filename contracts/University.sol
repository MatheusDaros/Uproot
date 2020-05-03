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

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function getCash() external returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256);
}


contract University is Ownable, AccessControl {
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
    // CLASSROOM_ROLE can manage itself inside the University and registering student applications
    bytes32 public constant CLASSROOM_ROLE = keccak256("CLASSROOM_ROLE");
    // READ_STUDENT_LIST_ROLE allow reading students list
    bytes32 public constant READ_STUDENT_LIST_ROLE = keccak256(
        "READ_STUDENT_LIST_ROLE"
    );
    // STUDENT_ROLE allow asking for grants and requesting a classroom from a successful application
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");

    // Parameter: Name of this University
    bytes32 public name;
    // Parameter: University cut from professor (Parts per Million)
    uint24 public cut;
    // List of every registered classroom
    Classroom[] public _classList;
    // List of every student
    Student[] _students;
    // Mapping of each student's applications
    mapping(address => address[]) _studentApplicationsMapping;
    // Address list of every donor
    address[] _donors;

    CERC20 public cToken;
    IERC20 public daiToken;

    constructor(
        bytes32 _name,
        uint24 _cut,
        address daiAddress,
        address compoundAddress
    ) public {
        name = _name;
        cut = _cut;
        _classList = new Classroom[](0);
        _students = new Student[](0);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(READ_STUDENT_LIST_ROLE, _msgSender());
        //Kovan address
        daiToken = IERC20(daiAddress);
        cToken = CERC20(compoundAddress);
    }

    event LogNewClassroom(bytes32, address);
    event LogChangeName(bytes32);
    event LogChangeCut(uint24);

    function changeName(bytes32 val) public onlyOwner {
        name = val;
        emit LogChangeName(name);
    }

    function changeCut(uint24 val) public onlyOwner {
        cut = val;
        emit LogChangeCut(cut);
    }

    function isValidClassroom(address classroom) public view returns (bool) {
        return hasRole(CLASSROOM_ROLE, classroom);
    }

    function studentIsRegistered(address student) public view returns (bool) {
        require(
            hasRole(READ_STUDENT_LIST_ROLE, _msgSender()),
            "University: caller doesn't have READ_STUDENT_LIST_ROLE"
        );
        return hasRole(STUDENT_ROLE, student);
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
    ) public {
        require(
            hasRole(CLASSLIST_ADMIN_ROLE, _msgSender()),
            "University: caller doesn't have CLASSLIST_ADMIN_ROLE"
        );
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
    ) internal {
        //TODO: fetch contract from external factory to reduce size
        Classroom classroom = new Classroom(
            cName,
            cCut,
            cPCut,
            minScore,
            entryPrice,
            duration,
            address(this),
            address(daiToken),
            address(cToken),
            challengeAddress
        );
        classroom.transferOwnership(owner);
        _classList.push(classroom);
        grantRole(READ_STUDENT_LIST_ROLE, address(classroom));
        grantRole(CLASSROOM_ROLE, address(classroom));
        emit LogNewClassroom(cName, address(classroom));
    }

    //TODO: Use GSN to improve UX for new student
    function studentSelfRegister(bytes32 sName) public {
        require(
            _studentApplicationsMapping[_msgSender()].length == 0,
            "University: student already registered"
        );
        _newStudent(sName, _msgSender());
    }

    function _newStudent(bytes32 sName, address addr) internal {
        //Gambiarra: Push address(0) in the mapping to mark that student as registered in the university
        _studentApplicationsMapping[addr].push(address(0));
        //TODO: fetch contract from external factory to reduce size
        Student student = new Student(sName, address(this));
        student.transferOwnership(addr);
        _students.push(student);
        grantRole(STUDENT_ROLE, address(student));
    }

    function registerStudentApplication(address student, address application)
        public
    {
        require(
            hasRole(CLASSROOM_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_ROLE"
        );
        _studentApplicationsMapping[student].push(application);
    }

    function viewMyApplications() public view returns (address[] memory) {
        return viewStudentApplications(_msgSender());
    }

    function viewStudentApplications(address addr)
        public
        view
        returns (address[] memory)
    {
        require(
            addr == _msgSender() || hasRole(GRANTS_MANAGER_ROLE, _msgSender()),
            "Classroom: read permission denied"
        );
        return _studentApplicationsMapping[addr];
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
    ) public {
        require(
            hasRole(STUDENT_ROLE, _msgSender()),
            "University: caller doesn't have STUDENT_ROLE"
        );
        StudentApplication application = StudentApplication(applicationAddr);
        require(
            checkForStudentApplication(_msgSender(), applicationAddr),
            "University: caller is not student of this application"
        );
        require(
            application.applicationState() == 3,
            "University: application is not successful"
        );
        _newClassRoom(
            Student(_msgSender()).owner(),
            cName,
            cCut,
            cPCut,
            minScore,
            entryPrice,
            duration,
            challenge
        );
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

    function addStudentScore(address student, int32 val) public {
        require(
            hasRole(CLASSROOM_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_ROLE"
        );
        Student(student).addScore(val);
    }

    function subStudentScore(address student, int32 val) public {
        require(
            hasRole(CLASSROOM_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_ROLE"
        );
        Student(student).subScore(val);
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

    //TODO: manage grants

    //TODO: implement funds manager

    //TODO: implement funds manager governance
}
