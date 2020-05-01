pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
        Dormant,
        Ready,
        Active,
        Success,
        Failed,
        Empty
    }

    IStudentAnswer _answer;
    ApplicationState _applicationState;
    address _studentAddress;
    address _classroomAddress;
    bytes32 _seed;
    bool _hasAnswer;

    constructor(address studentAddress, address classroomAddress, bytes32 classroomSeed) public {
        _applicationState = ApplicationState.Dormant;
        _studentAddress = studentAddress;
        _classroomAddress = classroomAddress;
        _hasAnswer = false;
        //Kovan address
        daiToken = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
        _seed = generateSeed(classroomSeed);
    }

    function generateSeed(bytes32 baseSeed) internal pure returns (bytes32) {
        //TODO:
        return baseSeed^"RANDOM";
    }

    function viewSeed() public view onlyOwner returns (bytes32) {
        return _seed;
    }

    function applicationState() public view returns (uint) {
        require(_msgSender() == _studentAddress || _msgSender() == owner(), "StudentApplication: read permission denied");
        return uint(_applicationState);
    }

    function payEntryPrice() external {
        require(_applicationState == ApplicationState.Dormant, "StudentApplication: application is not dormant");
        require(daiToken.transferFrom(msg.sender, _classroomAddress, Classroom(_classroomAddress).entryPrice()),
            "StudentApplication: could not transfer DAI");
        _applicationState = ApplicationState.Ready;
    }

    function activate() public onlyOwner {
        _applicationState = ApplicationState.Active;
    }

    function registerAnswer() public {
       require(_applicationState == ApplicationState.Active, "StudentApplication: application is not active");
       IStudentAnswer answer = IStudentAnswer(_msgSender());
       require(answer.getOwner() == _studentAddress, "StudentApplication: student is not owner of answer");
       _answer = answer;
       _hasAnswer = true;
    }

    function getHint1() public view returns (bytes32) {
        require(_hasAnswer, "StudentApplication: answer not registered");
        require(_msgSender() == address(_answer), "StudentApplication: are you cheating?");
        //TODO:
        return bytes32("HINT1") | _seed;
    }

    function getHint2() public view returns (bytes32) {
        require(_hasAnswer, "StudentApplication: answer not registered");
        require(_msgSender() == address(_answer), "StudentApplication: are you cheating?");
        //TODO:
        return bytes32("HINT2") | _seed;
    }

    function verifyAnswer() public view returns (bool) {
        return _answer.getSeed() == _seed;
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
}