pragma solidity ^0.6.6;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";


interface ILendingPool is IERC20 {
    function redirectInterestStream(address) external;

    function redirectInterestStreamOf(address, address) external;

    function allowInterestRedirectionTo(address) external;

    function redeem(uint256) external;

    function principalBalanceOf(address) external view returns (uint256);

    function isTransferAllowed(address, uint256) public view returns (bool);

    function getInterestRedirectionAddress(address)
        external
        view
        returns (address);

    function getRedirectedBalance(address) external view returns (uint256);
}


interface ILendingPoolCore {
    function getReserveATokenAddress(address) public view returns (address);
}
