pragma solidity 0.6.6;

interface IGrantsManager {

    function studentRequestGrant(uint256, address) external returns (bool);
    
}