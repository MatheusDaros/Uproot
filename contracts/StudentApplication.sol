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
import "./Classroom.sol";

contract StudentApplication is Ownable {
    using SafeMath for uint256;

    enum ApplicationState {
        Dormant,
        Ready,
        Active,
        Success,
        Failed
    }

    ApplicationState _applicationState;
    address _studentAddress;
    address _classroomAddress;

    constructor(address studentAddress, address classroomAddress) public {
        _applicationState = ApplicationState.Dormant;
        _studentAddress = studentAddress;
        _classroomAddress = classroomAddress;
    }

    function applicationState() public view returns (uint) {
        require(_msgSender() == _studentAddress || _msgSender() == owner(), "StudentApplication: read permission denied");
        return uint(_applicationState);
    }

    function activate() public onlyOwner {
        _applicationState = ApplicationState.Active;
    }
}