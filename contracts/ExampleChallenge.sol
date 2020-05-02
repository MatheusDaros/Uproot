pragma solidity 0.6.6;

import "./IClassroomChallenge.sol";

contract ExampleChallenge is IClassroomChallenge {

    function hintsCount() external pure override returns (uint) {
        return 2;
    }

    function getHint(uint index, bytes32 seed) public view override returns (bytes32) {
        if (index == 0) return bytes32("HACKMONEY") | seed;
        if (index == 1) return ~bytes32("HACKMONEY") | seed;
    }

    function viewMaterial() external pure override returns (string memory) {
        return "TODO: point a link to material hosted at IPFS using ENS";
    }
}