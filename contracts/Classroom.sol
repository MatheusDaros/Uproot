pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./University.sol";
import "./Student.sol";

contract Classroom is Ownable {
    using SafeMath for uint256;

    bytes32 _name;
    University _university;
    bool _openForApplication;
    Student[] _students;
    int32 _minScore;

    IERC20 public daiToken;
    CERC20 public cToken;

    constructor(bytes32 name, address universityAddress) public {
        _name = name;
        _university = University(universityAddress);
        _openForApplication = false;
        _minScore = 0;
        //Kovan address
        daiToken = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    }

    function setMinScore(int32 val) public onlyOwner {
        _minScore = val;
    }

    function applicationsState() public view returns (bool){
        return _openForApplication;
    }

    function openApplications() public onlyOwner {
        require(!_openForApplication, "Classroom: applications are already opened");
        require(_students.length == 0, "Classroom: students list not empty");
        _openForApplication = true;
    }

    function closeApplications() public onlyOwner {
        require(_openForApplication, "Classroom: applications are already closed");
        _openForApplication = false;
    }

    function studentApply() public{
        require(_university.studentIsRegistered(_msgSender()), "Classroom: student is not registered");
        require(_openForApplication, "Classroom: applications closed");
        Student applicant = Student(_msgSender());
        require(applicant.score() >= _minScore, "Classroom: student doesn't have enough score");
        _students.push(applicant);
    }
}