pragma solidity 0.6.6;

interface IStudentAnswer {
    function getOwner() external view returns (address);
    function getSeed() external view returns (bytes32);
}