pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";

contract UniversityFund is Ownable{
    using SafeMath for uint256;
    using Roles for Roles.Role;

    //_classListAdmin can add new manually created classes to the list
    Roles.Role private _classListAdmin;
    // _fundsManager can withdraw funds from the contract
    Roles.Role private _fundsManager;
    // _grantsManager can approve/decline grant claims
    Roles.Role private _grantsManager;

    // Address list of every registered classroom
    address[] _classList;

    constructor() public {                  
        _classList = new address[];        
    } 

    event NewClassroom(bytes32 indexed name, address addr);

    function classList() public view returns (address[]) {
        return _classList;
    }
    
    function newClassRoom(address addr, bytes32 name) public {
        // Only _classListAdmin can add new classroom
        require(_classListAdmin.has(msg.sender), "DOES_NOT_HAVE_CLASSLISTADMIN_ROLE");
        _newClassRoom(addr, name);
    }

    function _newClassRoom(address addr, bytes32 name) internal {
        _classList.push(addr);
        emit NewClassroom(name, addr);
    }

}