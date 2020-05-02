pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./University.sol";
import "./Student.sol";
import "./Classroom.sol";
import "./IStudentAnswer.sol";

contract StudentApplication is Ownable {
    using SafeMath for uint256;

    IERC20 public daiToken;

    enum ApplicationState {
        New,
        Ready,
        Active,
        Success,
        Failed,
        Empty,
        Expired
    }

    IStudentAnswer _answer;
    ApplicationState _applicationState;
    address _studentAddress;
    address _classroomAddress;
    bytes32 _seed;
    bool _hasAnswer;
    uint _principalReturned;
    uint _completionPrize;

    constructor(address studentAddress, address classroomAddress, address daiAddress, bytes32 classroomSeed) public {
        _applicationState = ApplicationState.New;
        _studentAddress = studentAddress;
        _classroomAddress = classroomAddress;
        _hasAnswer = false;
        //Kovan address
        daiToken = IERC20(daiAddress);
        _seed = generateSeed(classroomSeed);
    }

    function generateSeed(bytes32 baseSeed) internal pure returns (bytes32) {
        //TODO:
        return baseSeed^"RANDOM";
    }

    function viewSeed() public view onlyOwner returns (bytes32) {
        return _seed;
    }

    function studentAddress() public view onlyOwner returns (address) {
        return _studentAddress;
    }

    function applicationState() public view returns (uint) {
        require(_msgSender() == _studentAddress || _msgSender() == owner(), "StudentApplication: read permission denied");
        return uint(_applicationState);
    }

    function payEntryPrice() external {
        require(_applicationState == ApplicationState.New, "StudentApplication: application is not New");
        require(daiToken.transferFrom(msg.sender, _classroomAddress, Classroom(_classroomAddress).entryPrice()),
            "StudentApplication: could not transfer DAI");
        _applicationState = ApplicationState.Ready;
    }

    function activate() public onlyOwner {
        require( _applicationState == ApplicationState.New, "StudentApplication: application is not New");
        _applicationState = ApplicationState.Active;
    }

    function expire() public onlyOwner {
        require( _applicationState == ApplicationState.New, "StudentApplication: application is not New");
        _applicationState = ApplicationState.Expired;
    }

    function registerAnswer() public {
       require(_applicationState == ApplicationState.Active, "StudentApplication: application is not active");
       IStudentAnswer answer = IStudentAnswer(_msgSender());
       require(answer.getOwner() == _studentAddress, "StudentApplication: student is not owner of answer");
       _answer = answer;
       _hasAnswer = true;
    }

    //TODO: separate challenge in another smart contract

    function getHint1() public view returns (bytes32) {
        require(_hasAnswer, "StudentApplication: answer not registered");
        require(_msgSender() == address(_answer), "StudentApplication: are you cheating?");
        return bytes32("HACKMONEY") | _seed;
    }

    function getHint2() public view returns (bytes32) {
        require(_hasAnswer, "StudentApplication: answer not registered");
        require(_msgSender() == address(_answer), "StudentApplication: are you cheating?");
        return ~bytes32("HACKMONEY") | _seed;
    }

    function verifyAnswer() public view returns (bool) {
        try _answer.getSeed() returns (bytes32 seed) {
            return seed == _seed;
        }
        catch {
            return false;
        }
    }

    function registerFinalAnswer() public onlyOwner {
        if (!_hasAnswer) {
            _applicationState = ApplicationState.Empty;
        }
        else {
            if (verifyAnswer()) _applicationState = ApplicationState.Success;
            else _applicationState = ApplicationState.Failed;
        }
    }

    function accountAllowance(uint principal, uint prize) public onlyOwner {
        require(applicationState() > 2, "StudentApplication: application not finished yet");
        _principalReturned = principal;
        _completionPrize = prize;
    }

    function withdrawAllResults(address to) public {
        withdrawResults(to, _principalReturned + _completionPrize);
    }

    function withdrawResults(address to, uint val) public {
        require(_msgSender() == _studentAddress, "StudentApplication: only student can withdraw");
        require(applicationState() > 2, "StudentApplication: application not finished");
        daiToken.transferFrom(_classroomAddress, to, val);
    }

    //TODO: option to create classroom from success application
}