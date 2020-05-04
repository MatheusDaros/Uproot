pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Classroom.sol";
import "./University.sol";
import "./StudentApplication.sol";


contract Student is Ownable, AccessControl {
    using SafeMath for uint256;

    //READ_SCORE_ROLE can read student Score
    bytes32 public constant READ_SCORE_ROLE = keccak256("READ_SCORE_ROLE");
    //MODIFY_SCORE_ROLE can read student Score
    bytes32 public constant MODIFY_SCORE_ROLE = keccak256("MODIFY_SCORE_ROLE");

    bytes32 public name;
    University _university;
    address[] _classroomAddress;
    int32 _score;

    IERC20 public daiToken;
    CERC20 public cToken;

    constructor(bytes32 _name, address universityAddress) public {
        name = _name;
        _score = 0;
        _university = University(universityAddress);
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

    function changeName(bytes32 val) public onlyOwner {
        name = val;
        emit LogChangeName(name);
    }

    function score() public view returns (int32) {
        require(
            hasRole(READ_SCORE_ROLE, _msgSender()),
            "Student: caller doesn't have READ_SCORE_ROLE"
        );
        return _score;
    }

    function addScore(int32 val) public {
        require(
            hasRole(MODIFY_SCORE_ROLE, _msgSender()),
            "Student: caller doesn't have MODIFY_SCORE_ROLE"
        );
        require(_score < _score + val, "Student: good grades overflow");
        _score += val;
    }

    function subScore(int32 val) public {
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
        Classroom(classroomAddress).studentApply();
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
            Classroom(classroom).viewMyApplication(),
            to
        );
    }

    function withdrawResultsFromClassroom(
        address classroom,
        address to,
        uint256 val
    ) public onlyOwner {
        withdrawResultsFromApplication(
            Classroom(classroom).viewMyApplication(),
            to,
            val
        );
    }

    function withdrawAllResultsFromApplication(address application, address to)
        public
        onlyOwner
    {
        StudentApplication(application).withdrawAllResults(to);
    }

    function withdrawResultsFromApplication(
        address application,
        address to,
        uint256 val
    ) public onlyOwner {
        StudentApplication(application).withdrawResults(to, val);
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
}
