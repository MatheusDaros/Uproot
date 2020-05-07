pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IUniversity.sol";

contract ExampleFundsManager is Ownable {
    
    IUniversity public university;

    constructor(address universityAddress) public {
        university = IUniversity(universityAddress);
    }

    function triggerUpdate() public onlyOwner {
        
    }
}