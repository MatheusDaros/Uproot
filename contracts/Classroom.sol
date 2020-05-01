pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./University.sol";
import "./Student.sol";
import "./StudentApplication.sol";

contract Classroom is Ownable {
    using SafeMath for uint256;

    bytes32 _name;
    University _university;
    bool _openForApplication;
    StudentApplication[] _studentApplications;
    StudentApplication[] _validStudentApplications;
    mapping(address => address) _studentApplicationsLink;

    //Classroom parameters
    int32 _minScore;
    uint _entryPrice;

    IERC20 public daiToken;
    CERC20 public cToken;

    bool public classroomActive;

    constructor(bytes32 name, address universityAddress) public {
        _name = name;
        _university = University(universityAddress);
        _openForApplication = false;
        _minScore = 0;
        classroomActive = false;
        //Kovan address
        daiToken = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    }

    function name() public view returns (bytes32) {
        return _name;
    }

    function changeName(bytes32 val) public onlyOwner {
        _name = val;
    }

    function minScore() public view returns (int32) {
        return _minScore;
    }

    function setMinScore(int32 val) public onlyOwner {
        _minScore = val;
    }

    function entryPrice() public view returns (uint) {
        return _entryPrice;
    }

    function setEntryPrice(uint val) public onlyOwner {
        _entryPrice = val;
    }

    function applicationsState() public view returns (bool) {
        return _openForApplication;
    }

    function openApplications() public onlyOwner {
        require(!_openForApplication, "Classroom: applications are already opened");
        require(_studentApplications.length == 0, "Classroom: students list not empty");
        _openForApplication = true;
    }

    function closeApplications() public onlyOwner {
        require(_openForApplication, "Classroom: applications are already closed");
        _openForApplication = false;
        applyDAI();
    }

    function studentApply() public{
        require(_university.studentIsRegistered(_msgSender()), "Classroom: student is not registered");
        require(_openForApplication, "Classroom: applications closed");
        Student applicant = Student(_msgSender());
        require(applicant.score() >= _minScore, "Classroom: student doesn't have enough score");
        StudentApplication application = _createStudentApplication(applicant);
        _studentApplications.push(application);
    }

    function _createStudentApplication(Student student) internal returns (StudentApplication) {
        StudentApplication newApplication = new StudentApplication(address(student), address(this));
        _studentApplicationsLink[address(student)] = address(newApplication);
        return newApplication;
    }

    function beginClass() public onlyOwner {
        require(!_openForApplication, "Classroom: applications are still open");
        checkApplications();
        require(_validStudentApplications.length > 0, "Classroom: no ready application");
        classroomActive = true;
    }

    function checkApplications() internal {
        for (uint i = 0; i < _studentApplications.length ; i++) {
            if (_studentApplications[i].applicationState() == 1) {
                _studentApplications[i].activate();
                _validStudentApplications.push(_studentApplications[i]);
            }
        }
        _studentApplications = new StudentApplication[](0);
    }

    //public onlyOwner allow the professor to apply money before closing applications
    function applyDAI() public onlyOwner {
        uint balance = daiToken.balanceOf(address(this));
        require(balance > 0, "Classroom: no funds to apply");
        _name = "PLACEHOLDER";
        //TODO:
    }
}