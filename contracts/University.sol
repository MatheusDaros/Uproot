pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Classroom.sol";
import "./Student.sol";

interface CERC20 {
    function mint(uint256) external returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function supplyRatePerBlock() external returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
}

contract University is Ownable, AccessControl {
    using SafeMath for uint256;

    //CLASSLIST_ADMIN_ROLE can add new manually created classes to the list
    bytes32 public constant CLASSLIST_ADMIN_ROLE = keccak256("CLASSLIST_ADMIN_ROLE");
    // FUNDS_MANAGER_ROLE can withdraw funds from the contract
    bytes32 public constant FUNDS_MANAGER_ROLE = keccak256("FUNDS_MANAGER_ROLE");
    // GRANTS_MANAGER_ROLE can approve/decline grant claims
    bytes32 public constant GRANTS_MANAGER_ROLE = keccak256("GRANTS_MANAGER_ROLE");
    // CLASSROOM_ROLE can manage itself inside the University
    bytes32 public constant CLASSROOM_ROLE = keccak256("CLASSROOM_ROLE");
    // READ_STUDENT_LIST_ROLE allow reading students list
    bytes32 public constant READ_STUDENT_LIST_ROLE = keccak256("READ_STUDENT_LIST_ROLE");
    // STUDENT_ROLE allow asking for grants
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");

    // Name of this University
    bytes32 _name;
    // List of every registered classroom
    Classroom[] _classList;
    // List of every student
    Student[] _students;
    // Address list of every donor
    address[] _donors;

    CERC20 public cToken;
    IERC20 public daiToken;

    constructor(bytes32 name) public {
        _name = name;
        _classList = new Classroom[](0);
        _students = new Student[](0);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(READ_STUDENT_LIST_ROLE, _msgSender());
        //Kovan address
        daiToken = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    }

    event NewClassroom(bytes32 indexed name, address addr);

    function name() public view returns (bytes32){
        return _name;
    }

    function changeName(bytes32 val) public onlyOwner {
        _name = val;
    }

    function viewClassList() public view returns (Classroom[] memory) {
        return _classList;
    }

    function isValidClassroom(address classroom) public view returns (bool) {
        return hasRole(CLASSROOM_ROLE, classroom);
    }

    function newClassRoom(bytes32 cName) public {
        require(hasRole(CLASSLIST_ADMIN_ROLE, _msgSender()), "University: caller doesn't have CLASSLIST_ADMIN_ROLE");
        _newClassRoom(cName);
    }

    function _newClassRoom(bytes32 cName) internal {
        Classroom classroom = new Classroom(cName, address(this));
        classroom.transferOwnership(_msgSender());
        _classList.push(classroom);
        grantRole(READ_STUDENT_LIST_ROLE, address(classroom));
        grantRole(CLASSROOM_ROLE, address(classroom));
        emit NewClassroom(cName, address(classroom));
    }

    function studentSelfRegister(bytes32 sName) public {
        _newStudent(sName);
    }

    function _newStudent(bytes32 sName) internal {
        Student student = new Student(sName, address(this));
        student.transferOwnership(_msgSender());
        _students.push(student);
        grantRole(STUDENT_ROLE, address(student));
    }

    function studentIsRegistered(address student) public view returns (bool){
        require(hasRole(READ_STUDENT_LIST_ROLE, _msgSender()), "University: caller doesn't have READ_STUDENT_LIST_ROLE");
        return hasRole(STUDENT_ROLE, student);
    }

}