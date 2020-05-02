pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./University.sol";
import "./Student.sol";
import "./StudentApplication.sol";
import "./IClassroomChallenge.sol";

contract Classroom is Ownable {
    using SafeMath for uint256;

    University public university;
    bool public openForApplication;
    bool public courseFinished;
    StudentApplication[] _studentApplications;
    StudentApplication[] _validStudentApplications;
    mapping(address => address) _studentApplicationsLink;
    address[] _studentsLookUp;
    address[] _applicationsLookUp;
    uint _endDate;
    uint _totalBalance;

    //Classroom parameters
    bytes32 public name;
    uint24 public principalCut;
    uint24 public poolCut;
    int32 public minScore;
    uint public entryPrice;
    uint public duration;
    bytes32 _seed;

    IERC20 public daiToken;
    CERC20 public cToken;
    address public _challengeAddress;

    bool public classroomActive;

    constructor(bytes32 _name, uint24 _principalCut, uint24 _poolCut, int32 _minScore, uint _entryPrice,
            uint _duration, address universityAddress, address daiAddress, address compoundAddress, address challengeAddress) public {
        name = _name;
        principalCut = _principalCut;
        poolCut = _poolCut;
        minScore = _minScore;
        entryPrice = _entryPrice;
        duration = _duration;
        university = University(universityAddress);
        openForApplication = false;
        classroomActive = false;
        //Kovan address
        daiToken = IERC20(daiAddress);
        cToken = CERC20(compoundAddress);
        _challengeAddress = challengeAddress;
        _seed = generateSeed();
    }

    event LogOpenApplications();
    event LogCloseApplications();
    event LogCourseFinished();
    event LogChangeChallenge(address);
    event LogChangeName(bytes32);
    event LogChangePrincipalCut(uint24);
    event LogChangePoolCut(uint24);
    event LogChangeMinScore(int32);
    event LogChangeEntryPrice(uint);
    event LogChangeDuration(uint);

    function changeName(bytes32 val) public onlyOwner {
        name = val;
        emit LogChangeName(name);
    }

    function changePrincipalCut(uint24 val) public onlyOwner {
        principalCut = val;
        emit LogChangePrincipalCut(principalCut);
    }

    function changePoolCut(uint24 val) public onlyOwner {
        poolCut = val;
        emit LogChangePoolCut(poolCut);
    }

    function changeMinScore(int32 val) public onlyOwner {
        minScore = val;
        emit LogChangeMinScore(minScore);
    }

    function changeEntryPrice(uint val) public onlyOwner {
        entryPrice = val;
        emit LogChangeEntryPrice(entryPrice);
    }

    function changeDuration(uint val) public onlyOwner {
        duration = val;
        emit LogChangeDuration(duration);
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

    function changeChallenge(address addr) public onlyOwner {
        require(isClassroomEmpty(), "Classroom: can't change challenge now");
        _challengeAddress = addr;
        emit LogChangeChallenge(_challengeAddress);
    }
    //TODO: allow teacher to setup a custom challenge

    function isClassroomEmpty() public view returns (bool) {
        return _studentApplications.length.add(_validStudentApplications.length) == 0;
    }

    function isCourseOngoing() public view returns (bool) {
        return _validStudentApplications.length > 0;
    }

    function openApplications() public onlyOwner {
        require(!openForApplication, "Classroom: applications are already opened");
        require(_studentApplications.length == 0, "Classroom: students list not empty");
        openForApplication = true;
        emit LogOpenApplications();
    }

    function closeApplications() public onlyOwner {
        require(openForApplication, "Classroom: applications are already closed");
        openForApplication = false;
        emit LogCloseApplications();
    }

    //public onlyOwner allow the professor to apply money before and after closing applications
    function applyDAI() public onlyOwner {
        uint balance = daiToken.balanceOf(address(this));
        if (balance <= 0) return;
        daiToken.approve(address(cToken), balance);
        cToken.mint(balance);
    }

    function studentApply() public{
        require(_msgSender() != owner(), "Classroom: professor can't be its own student");
        require(university.studentIsRegistered(_msgSender()), "Classroom: student is not registered");
        require(openForApplication, "Classroom: applications closed");
        Student applicant = Student(_msgSender());
        require(applicant.score() >= minScore, "Classroom: student doesn't have enough score");
        StudentApplication application = _createStudentApplication(applicant);
        _studentApplications.push(application);
    }

    function _createStudentApplication(Student student) internal returns (StudentApplication) {
        //TODO: fetch contract from external factory to reduce size
        StudentApplication newApplication = new StudentApplication(address(student), address(this), address(daiToken), _challengeAddress, _seed);
        _studentApplicationsLink[address(student)] = address(newApplication);
        university.registerStudentApplication(address(student), address(newApplication));
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
        require(!openForApplication, "Classroom: applications are still open");
        require(daiToken.balanceOf(address(this)) == 0, "Classroom: invest all balance before begin");
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
    }

    function finishCourse() public onlyOwner {
        //TODO: use oracle
        require (_endDate <= block.timestamp, "Classroom: too soon to finish course");
        require (_validStudentApplications.length > 0, "Classroom: no applications");
        _totalBalance = _recoverInvestment();
        courseFinished = true;
        emit LogCourseFinished();
    }

    function _recoverInvestment() internal returns (uint) {
        uint balance = cToken.balanceOfUnderlying(address(this));
        cToken.redeemUnderlying(balance);
        return balance;
    }

    function processResults () public onlyOwner {
        require(courseFinished, "Classroom: course not finished");
        require(_totalBalance <= daiToken.balanceOf(address(this)), "Classroom: not enough DAI to proceed");
        (uint successCount, uint emptyCount) = _startAnswerVerification();
        (uint universityCut, uint[] memory studentAllowances) = _accountValues(successCount, emptyCount);
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

    function _accountValues(uint successCount, uint emptyCount) internal returns (uint, uint[] memory) {
        uint nStudents = _validStudentApplications.length;
        uint returnsPool = _totalBalance.sub(entryPrice.mul(nStudents));
        uint professorPaymentPerStudent = entryPrice.mul(principalCut).div(10 ** 6);
        uint studentPrincipalReturn = entryPrice.sub(professorPaymentPerStudent);
        uint successPool = returnsPool.mul(successCount).div(nStudents);
        uint professorTotalPoolSuccessShare = successPool.mul(poolCut).div(10 ** 6);
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
        uint universityEmptyShare = emptyCount.mul(entryPrice);
        uint universityPaymentShare = professorTotalPoolSuccessShare.mul(university.cut()).div(10 ** 6);
        uint notEmptyCount = nStudents.sub(emptyCount);
        uint universitySucessPoolShare = professorPaymentPerStudent.mul(notEmptyCount).mul(university.cut()).div(10 ** 6);
        return (universityEmptyShare.add(universityPaymentShare).add(universitySucessPoolShare), studentAllowances);
    }

    function _resolveStudentAllowances(uint[] memory studentAllowances) internal {
        for (uint i = 0; i < _validStudentApplications.length ; i++) {
            if (studentAllowances[i] > 0) daiToken.approve(address(_validStudentApplications[i]), studentAllowances[i]);
        }
    }

    function _resolveUniversityCut(uint universityCut) internal {
        daiToken.transfer(address(university), universityCut);
    }

    function _updateStudentScores() internal {
        for (uint i = 0; i < _validStudentApplications.length ; i++) {
            if (_validStudentApplications[i].applicationState() == 3)
                university.addStudentScore(_validStudentApplications[i].studentAddress(), 1);
            if (_validStudentApplications[i].applicationState() == 4)
                university.subStudentScore(_validStudentApplications[i].studentAddress(), 1);
            if (_validStudentApplications[i].applicationState() == 5)
                university.subStudentScore(_validStudentApplications[i].studentAddress(), 2);
        }
    }

    function _clearClassroom() internal {
        _validStudentApplications = new StudentApplication[](0);
        withdrawAllResults();
        _totalBalance = 0;
        courseFinished = false;
    }

    function withdrawAllResults() public onlyOwner {
        daiToken.transferFrom(address(this), owner(), daiToken.balanceOf(address(this)));
    }
}