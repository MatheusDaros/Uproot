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

    University _university;
    bool _openForApplication;
    StudentApplication[] _studentApplications;
    StudentApplication[] _validStudentApplications;
    mapping(address => address) _studentApplicationsLink;
    address[] _studentsLookUp;
    address[] _applicationsLookUp;
    uint _endDate;

    //Classroom parameters
    bytes32 _name;
    uint24 _principalCut;
    uint24 _poolCut;
    int32 _minScore;
    uint _entryPrice;
    uint _duration;
    bytes32 _seed;

    IERC20 public daiToken;
    CERC20 public cToken;

    bool public classroomActive;

    event warnOpenApplications();

    event warnCloseApplications();

    constructor(bytes32 name, uint24 principalCut, uint24 poolCut, int32 minScore, uint entryPrice,
            uint duration, address universityAddress, address daiAddress) public {
        _name = name;
        _university = University(universityAddress);
        _openForApplication = false;
        _principalCut = principalCut;
        _poolCut = poolCut;
        _minScore = minScore;
        _entryPrice = entryPrice;
        _duration = duration;
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

    function principalCut() public view returns (uint24){
        return _principalCut;
    }

    function changePrincipalCut(uint24 val) public onlyOwner {
        _principalCut = val;
    }

    function poolCut() public view returns (uint24){
        return _poolCut;
    }

    function changePoolCut(uint24 val) public onlyOwner {
        _poolCut = val;
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

    function viewAllApplications() public view onlyOwner returns (address[] memory) {
        return _applicationsLookUp;
    }

    function viewAllStudents() public view onlyOwner returns (address[] memory) {
        return _studentsLookUp;
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
        _studentsLookUp.push(address(student));
        _applicationsLookUp.push(address(newApplication));
        return newApplication;
    }

    function viewMyApplication() public view returns (address) {
        return viewApplication(_msgSender());
    }

    function viewApplication(address addr) public view returns (address) {
        require(addr == _msgSender() || _msgSender() == owner(), "Classroom: read permission denied");
        return _studentApplicationsLink[addr];
    }

    function beginCourse() public onlyOwner {
        require(!_openForApplication, "Classroom: applications are still open");
        checkApplications();
        _studentApplications = new StudentApplication[](0);
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
                _studentApplications[i].expire();
            }
        }
        _studentApplications = new StudentApplication[](0);
    }

    function finishCourse() public onlyOwner {
        //TODO: use oracle
        require (_endDate <= block.timestamp, "Classroom: too soon to finish course");
        require (_validStudentApplications.length > 0, "Classroom: no applications");
        (uint successCount, uint emptyCount) = _startAnswerVerification();
        uint totalBalance = _recoverInvestment();
        (uint universityCut, uint[] memory studentAllowances) = _accountValues(totalBalance, successCount, emptyCount);
        _resolveStudentAllowances(studentAllowances);
        _resolveUniversityCut(universityCut);
        _updateStudentScores();
        _clearClassroom();
    }

    function _startAnswerVerification() internal returns (uint, uint) {
        uint successCount = 0;
        uint emptyCount = 0;
        for (uint i = 0; i < _validStudentApplications.length ; i++) {
            _validStudentApplications[i].registerFinalAnswer();
            if (_validStudentApplications[i].applicationState() == 3) successCount++;
            if (_validStudentApplications[i].applicationState() == 5) emptyCount++;
        }
        return (successCount, emptyCount);
    }

    function _recoverInvestment() internal returns (uint) {
        
        return daiToken.balanceOf(address(this));
    }

    function _accountValues(uint totalBalance, uint successCount, uint emptyCount) internal returns (uint, uint[] memory) {
        uint nStudents = _validStudentApplications.length;
        uint returnsPool = totalBalance.sub(_entryPrice.mul(nStudents));
        uint professorPaymentPerStudent = _entryPrice.mul(_principalCut).div(10 ** 6);
        uint studentPrincipalReturn = _entryPrice.sub(professorPaymentPerStudent);
        uint successPool = returnsPool.mul(successCount).div(nStudents);
        uint professorTotalPoolSuccessShare = successPool.mul(_poolCut).div(10 ** 6);
        uint successStudentPoolShare = returnsPool.sub(professorTotalPoolSuccessShare).div(successCount);
        uint[] memory studentAllowances = new uint[](nStudents);
        for (uint i = 0; i < nStudents ; i++) {
            if (_validStudentApplications[i].applicationState() == 3) {
                _validStudentApplications[i].accountAllowance(studentPrincipalReturn, successStudentPoolShare);
                studentAllowances[i] = studentPrincipalReturn.add(successStudentPoolShare);
            }
            if (_validStudentApplications[i].applicationState() == 4){
                _validStudentApplications[i].accountAllowance(studentPrincipalReturn, 0);
                studentAllowances[i] = studentPrincipalReturn;
            }
            if (_validStudentApplications[i].applicationState() == 5)
                _validStudentApplications[i].accountAllowance(0, 0);
        }
        uint universityEmptyShare = emptyCount.mul(_entryPrice);
        uint universityPaymentShare = professorTotalPoolSuccessShare.mul(_university.cut()).div(10 ** 6);
        uint notEmptyCount = nStudents.sub(emptyCount);
        uint universitySucessPoolShare = professorPaymentPerStudent.mul(notEmptyCount).mul(_university.cut()).div(10 ** 6);
        return (universityEmptyShare.add(universityPaymentShare).add(universitySucessPoolShare), studentAllowances);
    }

    function _resolveStudentAllowances(uint[] memory studentAllowances) internal {
        for (uint i = 0; i < _validStudentApplications.length ; i++) {
            if (studentAllowances[i] > 0) daiToken.approve(address(_validStudentApplications[i]), studentAllowances[i]);
        }
    }

    function _resolveUniversityCut(uint universityCut) internal {
        //TODO:
    }

    function _updateStudentScores() internal {
        for (uint i = 0; i < _validStudentApplications.length ; i++) {
            //TODO:
        }
    }

    function _clearClassroom() internal {
        _validStudentApplications = new StudentApplication[](0);
    }
}