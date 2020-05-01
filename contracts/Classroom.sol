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
    uint _endDate;

    //Classroom parameters
    int32 _minScore;
    uint _entryPrice;
    uint _duration;
    bytes32 _seed;

    IERC20 public daiToken;
    CERC20 public cToken;

    bool public classroomActive;

    event warnOpenApplications();

    event warnCloseApplications();

    constructor(bytes32 name, address universityAddress, address daiAddress) public {
        _name = name;
        _university = University(universityAddress);
        _openForApplication = false;
        _minScore = 0;
        _duration = 30 days;
        classroomActive = false;
        //Kovan address
        daiToken = IERC20(daiAddress);
        _seed = generateSeed();
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

    function duration() public view returns (uint) {
        return _duration;
    }

    function setDuration(uint val) public onlyOwner {
        _duration = val;
    }

    function applicationsState() public view returns (bool) {
        return _openForApplication;
    }

    function generateSeed() internal pure returns (bytes32) {
        //TODO:
        return "RANDOM";
    }

    function viewSeed() public view onlyOwner returns (bytes32) {
        return _seed;
    }

    function openApplications() public onlyOwner {
        require(!_openForApplication, "Classroom: applications are already opened");
        require(_studentApplications.length == 0, "Classroom: students list not empty");
        _openForApplication = true;
        emit warnOpenApplications();
    }

    function closeApplications() public onlyOwner {
        require(_openForApplication, "Classroom: applications are already closed");
        _openForApplication = false;
        applyDAI();
        emit warnCloseApplications();
    }

    //public onlyOwner allow the professor to apply money before closing applications
    function applyDAI() public onlyOwner {
        uint balance = daiToken.balanceOf(address(this));
        require(balance > 0, "Classroom: no funds to apply");
        _name = "PLACEHOLDER";
        //TODO:
    }

    function studentApply() public{
        require(_msgSender() != owner(), "Classroom: professor can't be its own student");
        require(_university.studentIsRegistered(_msgSender()), "Classroom: student is not registered");
        require(_openForApplication, "Classroom: applications closed");
        Student applicant = Student(_msgSender());
        require(applicant.score() >= _minScore, "Classroom: student doesn't have enough score");
        StudentApplication application = _createStudentApplication(applicant);
        _studentApplications.push(application);
    }

    function _createStudentApplication(Student student) internal returns (StudentApplication) {
        //TODO: fetch contract from external factory to reduce size
        StudentApplication newApplication = new StudentApplication(address(student), address(this), address(daiToken), _seed);
        _studentApplicationsLink[address(student)] = address(newApplication);
        return newApplication;
    }

    function beginClass() public onlyOwner {
        require(!_openForApplication, "Classroom: applications are still open");
        checkApplications();
        require(_validStudentApplications.length > 0, "Classroom: no ready application");
        classroomActive = true;
        //TODO: use oracle
        _endDate = block.timestamp.add(_duration);
    }

    function checkApplications() internal {
        for (uint i = 0; i < _studentApplications.length ; i++) {
            if (_studentApplications[i].applicationState() == 1) {
                _studentApplications[i].activate();
                _validStudentApplications.push(_studentApplications[i]);
            }
            else {
                
            }
        }
        _studentApplications = new StudentApplication[](0);
    }

    function startAnswerVerification() public onlyOwner {
        //TODO: use oracle
        require (_endDate <= block.timestamp, "Classroom: too soon to finish course");
        for (uint i = 0; i < _validStudentApplications.length ; i++) {

        }
    }
}