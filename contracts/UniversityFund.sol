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
import "./Classroom.sol";
import "./Student.sol";

interface CERC20 {
    function mint(uint256) external returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function supplyRatePerBlock() external returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
}

contract UniversityFund is Ownable, AccessControl {
    using SafeMath for uint256;

    //classListAdmin can add new manually created classes to the list
    bytes32 public constant CLASSLIST_ADMIN_ROLE = keccak256("CLASSLIST_ADMIN_ROLE");
    // fundsManager can withdraw funds from the contract
    bytes32 public constant FUNDS_MANAGER_ROLE = keccak256("FUNDS_MANAGER_ROLE");
    // grantsManager can approve/decline grant claims
    bytes32 public constant GRANTS_MANAGER_ROLE = keccak256("GRANTS_MANAGER_ROLE");

    // Address list of every registered classroom
    address[] _classList;
    // Address list of every donor
    address[] _donors;

    CERC20 public cToken;
    IERC20 public daiToken;

    constructor() public {
        _classList = new address[](0);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        //Kovan address
        daiToken = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    }

    event NewClassroom(bytes32 indexed name, address addr);

    function newClassRoom(bytes32 name) public {
        require(hasRole(CLASSLIST_ADMIN_ROLE, msg.sender), "DOES_NOT_HAVE_CLASSLIST_ADMIN_ROLE");
        _newClassRoom(name);
    }

    function _newClassRoom(bytes32 name) internal {
        Classroom classroom = new Classroom(name, address(this));
        classroom.transferOwnership(msg.sender);
        _classList.push(address(classroom));
        emit NewClassroom(name, address(classroom));
    }

}