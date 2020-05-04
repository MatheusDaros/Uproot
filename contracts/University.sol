pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./gambi/BaseRelayRecipient.sol";
import "./gambi/GSNTypes.sol";
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

    function balanceOfUnderlying(address) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function repayBorrowBehalf(address, uint256) external returns (uint256);
}


//TODO: Natspec Document ENVERYTHING
//TODO: Sort function order from all contracts

contract University is Ownable, AccessControl, BaseRelayRecipient {
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

    //TODO: resolve students and classrooms addresses using ENS

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
        daiToken = IERC20(daiAddress);
        cToken = CERC20(compoundAddress);
    }

    event LogNewClassroom(bytes32, address);
    event LogChangeName(bytes32);
    event LogChangeCut(uint24);

    function acceptRelayedCall(
        GSNTypes.RelayRequest calldata relayRequest,
        bytes calldata,
        uint256
    )
    external
    pure 
    returns (bytes memory context) {
        require(readBytes4(relayRequest.encodedFunction, 0) == this.studentSelfRegisterGSN.selector, "University: GSN not enabled for this function");
        return abi.encode(relayRequest.target, 0);
    }

    function readBytes4(bytes memory b, uint256 index)
        internal
        pure
        returns (bytes4 result)
    {
        index += 32;
        assembly {
            result := mload(add(b, index))
            result := and(
                result,
                0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
            )
        }
        return result;
    }

    function preRelayedCall(bytes calldata context) external returns (bytes32) {

    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        bytes32 preRetVal,
        uint256 gasUseWithoutPost,
        GSNTypes.GasData calldata gasData
    ) external {

    }

    function changeName(bytes32 val) public onlyOwner {
        name = val;
        emit LogChangeName(name);
    }

    function changeCut(uint24 val) public onlyOwner {
        cut = val;
        emit LogChangeCut(cut);
    }

    function isValidClassroom(address classroom) public view returns (bool) {
        return hasRole(CLASSROOM_PROFESSOR_ROLE, classroom);
    }

    function studentIsRegistered(address student) public view returns (bool) {
        require(
            hasRole(READ_STUDENT_LIST_ROLE, _msgSender()),
            "University: caller doesn't have READ_STUDENT_LIST_ROLE"
        );
        return hasRole(STUDENT_IDENTITY_ROLE, student);
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
            challengeAddress,
            address(daiToken),
            address(cToken)
        );
        classroom.transferOwnership(owner);
        _classList.push(classroom);
        grantRole(READ_STUDENT_LIST_ROLE, address(classroom));
        grantRole(CLASSROOM_PROFESSOR_ROLE, address(classroom));
        emit LogNewClassroom(cName, address(classroom));
    }

    function studentSelfRegisterGSN(bytes32 sName) public {
        require(
            _studentApplicationsMapping[_msgSenderGSN()].length == 0,
            "University: student already registered"
        );
        _newStudent(sName, _msgSenderGSN());
        //TODO: fund student GSNPaymaster
    }

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
        grantRole(STUDENT_IDENTITY_ROLE, address(student));
    }

    function registerStudentApplication(address student, address application)
        public
    {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
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
            hasRole(STUDENT_IDENTITY_ROLE, _msgSender()),
            "University: caller doesn't have STUDENT_IDENTITY_ROLE"
        );
        require(
            checkForStudentApplication(_msgSender(), applicationAddr),
            "University: caller is not student of this application"
        );
        StudentApplication application = StudentApplication(applicationAddr);
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
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        Student(student).addScore(val);
    }

    function subStudentScore(address student, int32 val) public {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
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

    //TODO: fund

    //TODO: manage grants

    //TODO: implement funds manager

    //TODO: implement funds manager governance
}
