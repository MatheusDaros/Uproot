pragma solidity 0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/IUniversity.sol";
import "./interface/IGrantsManager.sol";
import "./interface/IStudent.sol";
import "./interface/IStudentApplication.sol";


contract ExampleGrantsManager is Ownable, IGrantsManager {
    using SafeMath for uint256;

    address _universityAddress;

    mapping(address => uint256[]) _grantsLookup;
    address[] _studentsLookup;
    mapping(address => bool) _preApprovedStudents;
    uint32 _requiredAvg;
    uint32 _requiredCount;
    uint256 _maximumPrice;

    constructor(address universityAddress) public {
        _universityAddress = universityAddress;
    }

    function changeRequiredAvg(uint32 val) public onlyOwner {
        _requiredAvg = val;
    }

    function changeRequiredCount(uint32 val) public onlyOwner {
        _requiredCount = val;
    }

    function changeMaximumPrice(uint256 val) public onlyOwner {
        _maximumPrice = val;
    }

    function markStudent(address student, bool val) public onlyOwner {
        _preApprovedStudents[student] = val;
    }

    function viewAllStudents() public override returns (address[] memory) {
        require(
            _msgSender() == _universityAddress || _msgSender() == owner(),
            "GrantsManager: Read permission denied"
        );
        return _studentsLookup;
    }

    function viewAllGrantsForStudent(address student) public override returns (uint256[] memory){
        require(
            _msgSender() == _universityAddress || _msgSender() == owner(),
            "GrantsManager: Read permission denied"
        );
        _grantsLookup[student];
    }

    function giveGrant(address studentApplication) internal {
        IUniversity(_universityAddress).giveGrant(studentApplication);
    }

    function studentRequestGrant(uint256 price, address studentApplication)
        public
        override
        returns (bool)
    {
        require(
            IUniversity(_universityAddress).studentIsRegistered(_msgSender()),
            "GrantsManager: Student is not registered"
        );
        if (price > _maximumPrice) return false;
        if (
            _preApprovedStudents[_msgSender()] || _approvalCriteria(_msgSender())
        ) {
            giveGrant(studentApplication);
            _studentsLookup.push(_msgSender());
            _grantsLookup[_msgSender()].push(price);
            return true;
        }
        return false;
    }

    function _approvalCriteria(address student) internal view returns (bool) {
        int32 score = IStudent(student).score();
        if (score < 0) return false;
        uint256 count = IUniversity(_universityAddress)
            .viewStudentApplications(student)
            .length;
        if (count < _requiredCount) return false;
        uint256 avgScore = uint256(score).div(count);
        return avgScore > _requiredAvg;
    }
}
