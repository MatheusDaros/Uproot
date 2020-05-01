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

contract StudentApplication is Ownable {
    using SafeMath for uint256;

    IERC20 public daiToken;

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
        daiToken = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    }

    function applicationState() public view returns (uint) {
        require(_msgSender() == _studentAddress || _msgSender() == owner(), "StudentApplication: read permission denied");
        return uint(_applicationState);
    }

    function payEntryPrice() external {
        require(daiToken.transferFrom(msg.sender, _classroomAddress, Classroom(_classroomAddress).entryPrice()),
            "StudentApplication: could not transfer DAI");
        _applicationState = ApplicationState.Ready;
    }

    function activate() public onlyOwner {
        _applicationState = ApplicationState.Active;
    }
}