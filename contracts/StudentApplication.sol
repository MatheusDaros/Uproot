pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interface/IUniversity.sol";
import "./interface/IStudent.sol";
import "./interface/IClassroom.sol";
import "./interface/IStudentApplication.sol";
import "./interface/IStudentAnswer.sol";
import "./interface/IClassroomChallenge.sol";


contract StudentApplication is Ownable, IStudentApplication {
    using SafeMath for uint256;

    IERC20 public daiToken;
    IClassroomChallenge _challenge;

    enum ApplicationState {New, Ready, Active, Success, Failed, Empty, Expired}

    IStudentAnswer _answer;
    ApplicationState _applicationState;
    address _studentAddress;
    address _classroomAddress;
    bytes32 _seed;
    bool _hasAnswer;
    uint256 _principalReturned;
    uint256 _completionPrize;
    uint256 _entryPrice;

    constructor(
        address studentAddress,
        address classroomAddress,
        address daiAddress,
        address challengeAddress,
        bytes32 seed
    ) public {
        _applicationState = ApplicationState.New;
        _studentAddress = studentAddress;
        _classroomAddress = classroomAddress;
        _hasAnswer = false;
        daiToken = IERC20(daiAddress);
        _seed = seed;
        _challenge = IClassroomChallenge(challengeAddress);
        _entryPrice = IClassroom(_classroomAddress).entryPrice();
    }

    function studentAddress() public view override onlyOwner returns (address) {
        return _studentAddress;
    }

    function applicationState() public view override returns (uint256) {
        require(
            _msgSender() == _studentAddress || _msgSender() == owner(),
            "StudentApplication: read permission denied"
        );
        return uint256(_applicationState);
    }

    function entryPrice() public view override returns (uint256) {
        require(
            _msgSender() == _studentAddress || _msgSender() == owner(),
            "StudentApplication: read permission denied"
        );
        return _entryPrice;
    }

    function challengeAddress() public view returns (address) {
        require(
            _msgSender() == _studentAddress || _msgSender() == owner(),
            "StudentApplication: read permission denied"
        );
        return address(_challenge);
    }

    function payEntryPrice() external override {
        require(
            _applicationState == ApplicationState.New,
            "StudentApplication: application is not New"
        );
        TransferHelper.safeTransferFrom(
            address(daiToken),
            msg.sender,
            _classroomAddress,
            _entryPrice
        );
        _applicationState = ApplicationState.Ready;
    }

    function activate() public override onlyOwner {
        require(
            _applicationState == ApplicationState.New,
            "StudentApplication: application is not New"
        );
        _applicationState = ApplicationState.Active;
    }

    function expire() public override onlyOwner {
        require(
            _applicationState == ApplicationState.New,
            "StudentApplication: application is not New"
        );
        _applicationState = ApplicationState.Expired;
    }

    function registerAnswer() public override {
        require(
            _applicationState == ApplicationState.Active,
            "StudentApplication: application is not active"
        );
        IStudentAnswer answer = IStudentAnswer(_msgSender());
        require(
            answer.getOwner() == _studentAddress,
            "StudentApplication: getOwner result is wrong"
        );
        _answer = answer;
        _hasAnswer = true;
    }

    function viewChallengeMaterial() public view returns (string memory) {
        require(
            _msgSender() == _studentAddress || _msgSender() == owner(),
            "StudentApplication: read permission denied"
        );
        return _challenge.viewMaterial();
    }

    function getHint(uint256 index) public view override returns (bytes32) {
        require(_hasAnswer, "StudentApplication: answer not registered");
        require(
            _msgSender() == address(_answer),
            "StudentApplication: are you cheating?"
        );
        require(
            index < _challenge.hintsCount(),
            "StudentApplication: hint not available"
        );
        return _challenge.getHint(index, _seed);
    }

    function verifyAnswer() public view returns (bool) {
        try _answer.getSeed() returns (bytes32 seed) {
            return seed == _seed;
        } catch {
            return false;
        }
    }

    function registerFinalAnswer() public override onlyOwner {
        if (!_hasAnswer) {
            _applicationState = ApplicationState.Empty;
        } else {
            if (verifyAnswer()) _applicationState = ApplicationState.Success;
            else _applicationState = ApplicationState.Failed;
        }
    }

    function accountAllowance(uint256 principal, uint256 prize)
        public
        override
        onlyOwner
    {
        require(
            applicationState() > 2,
            "StudentApplication: application not finished yet"
        );
        _principalReturned = principal;
        _completionPrize = prize;
    }

    function withdrawAllResults(address to) public override {
        withdrawResults(to, _principalReturned + _completionPrize);
    }

    function withdrawResults(address to, uint256 val) public override {
        require(
            _msgSender() == _studentAddress,
            "StudentApplication: only student can withdraw"
        );
        require(
            applicationState() > 2,
            "StudentApplication: application not finished"
        );
        TransferHelper.safeTransferFrom(address(daiToken), _classroomAddress, to, val);
    }
}
