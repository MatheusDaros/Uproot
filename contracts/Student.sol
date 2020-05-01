pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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

    bytes32 _name;
    University _university;
    address[] _classroomAddress;
    int32 _score;

    IERC20 public daiToken;
    CERC20 public cToken;

    constructor(bytes32 name, address universityAddress) public {
        _name = name;
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
        //Kovan address
        daiToken = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    }

    function name() public view returns (bytes32){
        return _name;
    }

    function changeName(bytes32 val) public onlyOwner {
        _name = val;
    }

    function score() public view returns(int32) {
        require(hasRole(READ_SCORE_ROLE, _msgSender()), "Student: caller doesn't have READ_SCORE_ROLE");
        return _score;
    }

    function addScore(int32 val) public  {
        require(hasRole(MODIFY_SCORE_ROLE, _msgSender()), "Student: caller doesn't have MODIFY_SCORE_ROLE");
        _score += val;
    }

    function subtractScore(int32 val) public  {
        require(hasRole(MODIFY_SCORE_ROLE, _msgSender()), "Student: caller doesn't have MODIFY_SCORE_ROLE");
        _score -= val;
    }

    function applyToClassroom(address classroomAddress) public onlyOwner {
        require(_university.isValidClassroom(classroomAddress), "Student: address is not a valid classroom");
        grantRole(READ_SCORE_ROLE, classroomAddress);
        Classroom(classroomAddress).studentApply();
        _classroomAddress.push(classroomAddress);
    }

    // not a feature but it is something a teacher would sometimes want to do
    function removeFromMyClassroom() public {
        for (uint i = 0; i < _classroomAddress.length; i++) {
            if (_classroomAddress[i] == _msgSender()) _classroomAddress[i] = address(0);
        }
    }

}