pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./gambi/BaseRelayRecipient.sol";
import "./gambi/GSNTypes.sol";
import "./interface/IStudent.sol";
import "./interface/IClassroom.sol";
import "./interface/IUniversity.sol";
import "./interface/IStudentApplication.sol";
import "./interface/IGrantsManager.sol";
import "./MyUtils.sol";


contract Student is Ownable, AccessControl, BaseRelayRecipient, IStudent {
    using SafeMath for uint256;

    //READ_SCORE_ROLE can read student Score
    bytes32 public constant READ_SCORE_ROLE = keccak256("READ_SCORE_ROLE");
    //MODIFY_SCORE_ROLE can read student Score
    bytes32 public constant MODIFY_SCORE_ROLE = keccak256("MODIFY_SCORE_ROLE");

    bytes32 public name;
    IUniversity _university;
    address[] _classroomAddress;
    int32 _score;

    IERC20 public daiToken;

    constructor(bytes32 _name, address payable universityAddress) public {
        name = _name;
        _score = 0;
        _university = IUniversity(universityAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(READ_SCORE_ROLE, _msgSender());
        grantRole(MODIFY_SCORE_ROLE, universityAddress);
        if (_msgSender() != universityAddress) {
            grantRole(READ_SCORE_ROLE, universityAddress);
            grantRole(DEFAULT_ADMIN_ROLE, universityAddress);
            renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
        }
    }

    event LogChangeName(bytes32);

    function ownerStudent() public view override returns (address) {
        return owner();
    }

    function changeName(bytes32 val) public onlyOwner {
        name = val;
        emit LogChangeName(name);
    }

    function score() public view override returns (int32) {
        require(
            hasRole(READ_SCORE_ROLE, _msgSender()),
            "Student: caller doesn't have READ_SCORE_ROLE"
        );
        return _score;
    }

    function addScore(int32 val) public override {
        require(
            hasRole(MODIFY_SCORE_ROLE, _msgSender()),
            "Student: caller doesn't have MODIFY_SCORE_ROLE"
        );
        require(_score < _score + val, "Student: good grades overflow");
        _score += val;
    }

    function subScore(int32 val) public override {
        require(
            hasRole(MODIFY_SCORE_ROLE, _msgSender()),
            "Student: caller doesn't have MODIFY_SCORE_ROLE"
        );
        require(_score > _score - val, "Student: bad grades overflow");
        _score -= val;
    }

    function applyToClassroom(address classroomAddress) public onlyOwner {
        require(
            _university.isValidClassroom(classroomAddress),
            "Student: address is not a valid classroom"
        );
        grantRole(READ_SCORE_ROLE, classroomAddress);
        IClassroom(classroomAddress).studentApply();
        _classroomAddress.push(classroomAddress);
    }

    // not a feature but it is something a teacher would sometimes want to do
    function removeFromMyClassroom() public {
        for (uint256 i = 0; i < _classroomAddress.length; i++) {
            if (_classroomAddress[i] == _msgSender())
                _classroomAddress[i] = address(0);
        }
    }

    function withdrawAllResultsFromClassroom(address classroom, address to)
        public
        onlyOwner
    {
        withdrawAllResultsFromApplication(
            IClassroom(classroom).viewMyApplication(),
            to
        );
    }

    function withdrawResultsFromClassroom(
        address classroom,
        address to,
        uint256 val
    ) public onlyOwner {
        withdrawResultsFromApplication(
            IClassroom(classroom).viewMyApplication(),
            to,
            val
        );
    }

    function withdrawAllResultsFromApplication(address application, address to)
        public
        onlyOwner
    {
        IStudentApplication(application).withdrawAllResults(to);
    }

    function withdrawResultsFromApplication(
        address application,
        address to,
        uint256 val
    ) public onlyOwner {
        IStudentApplication(application).withdrawResults(to, val);
    }

    function requestClassroom(
        address applicationAddr,
        bytes32 cName,
        uint24 cCut,
        uint24 cPCut,
        int32 minScore,
        uint256 entryPrice,
        uint256 duration,
        address challenge
    ) public onlyOwner {
        _university.studentRequestClassroom(
            applicationAddr,
            cName,
            cCut,
            cPCut,
            minScore,
            entryPrice,
            duration,
            challenge
        );
    }

    function requestGrant(address grantsManager, address studentApplication) public onlyOwner {
        require(MyUtils.searchInsideArray(address(this), _university.viewMyApplications()), "Student: wrong application address");
        uint256 price = IStudentApplication(studentApplication).entryPrice();
        grantRole(READ_SCORE_ROLE, grantsManager);
        IGrantsManager(grantsManager).studentRequestGrant(price, studentApplication);
    }

    function transferOwnershipStudent(address newOwner) public override {
        transferOwnership(newOwner);
    }

    function acceptRelayedCall(
        GSNTypes.RelayRequest calldata relayRequest,
        bytes calldata,
        uint256
    ) external view returns (bytes memory context) {
        require(
            _msgSenderGSN() == owner(),
            "Student: GSN enabled only for the student"
        );
        return abi.encode(relayRequest.target, 0);
    }

    function preRelayedCall(bytes calldata) external returns (bytes32) {}

    function postRelayedCall(
        bytes calldata,
        bool success,
        bytes32,
        uint256,
        GSNTypes.GasData calldata
    ) external {}
}
