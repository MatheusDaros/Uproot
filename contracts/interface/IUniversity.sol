pragma solidity 0.6.6;


interface IUniversity {
    function cut() external view returns (uint24);

    function isValidClassroom(address) external view returns (bool);

    function studentRequestClassroom(
        address,
        bytes32,
        uint24,
        uint24,
        int32,
        uint256,
        uint256,
        address
    ) external returns (address);

    function studentIsRegistered(address) external view returns (bool);

    function registerStudentApplication(address, address) external;

    function addStudentScore(address, int32) external;

    function subStudentScore(address, int32) external;
}
