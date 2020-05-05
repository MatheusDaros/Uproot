pragma solidity 0.6.6;


interface IUniversity {
    function name() external view returns (bytes32);

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

    function viewMyApplications() 
        external
        view
        returns (address[] memory);

    function viewStudentApplications(address)
        external
        view
        returns (address[] memory);

    function studentIsRegistered(address) external view returns (bool);

    function registerStudentApplication(address, address) external;

    function addStudentScore(address, int32) external;

    function subStudentScore(address, int32) external;

    function giveGrant(address) external;

    function donateDai(uint256) external;
}
