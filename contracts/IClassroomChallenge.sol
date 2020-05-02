pragma solidity 0.6.6;

//TODO: map all attack vectors

interface IClassroomChallenge {
    function hintsCount() external pure returns (uint);
    function getHint(uint, bytes32) external view returns (bytes32);
    function viewMaterial() external pure returns (string memory);
}