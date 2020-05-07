pragma solidity 0.6.6;


interface IUniversity {
    function name() external view returns (bytes32);

    function availableFunds() external view returns (uint256);

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

    function viewMyApplications() external view returns (address[] memory);

    function viewStudentApplications(address)
        external
        view
        returns (address[] memory);

    function studentIsRegistered(address) external view returns (bool);

    function registerStudentApplication(address, address) external;

    function addStudentScore(address, int32) external;

    function subStudentScore(address, int32) external;

    function giveGrant(address, uint256) external;

    function donateETH(uint256) external payable;

    function donateDAI(uint256) external;

    function swapDAI_ETH(uint256, uint256) external returns (uint256[] memory);

    function swapETH_DAI(uint256, uint256) external returns (uint256[] memory);

    function reinvestReturns(uint256) external;

    function accountRevenue(uint256) external;

    function applyFundsCompound(uint256) external;

    function recoverFundsCompound(uint256) external;

    function applyFundsAave(uint256) external;

    function recoverFundsAave(uint256) external;

    function spendBudget(address, uint256) external;

    function enterCompoundDAIMarket() external;

    function exitCompoundDAIMarket() external;

    function enterCompoundMarket(address) external;

    function exitCompoundMarket(address) external;

    function setAaveMarketCollateralForDAI(bool) external;

    function setAaveMarketCollateral(address, bool) external;

    function getCompoundLiquidityAndShortfall()
        external
        view
        returns (uint256, uint256);

    function getCompoundPriceInWEI(address) 
        external 
        view 
        returns (uint256);

    function getCompoundMaxBorrowInWEI(address) 
        external 
        view 
        returns (uint256);
    
    function compoundBorrow(address, uint256) external;

    function compoundGetBorrow(address) external view returns (uint256);

    function compoundRepayBorrow(address, address, uint256) external;

    function aaveGetBorrow(address, uint256, bool) external;

    function aaveRepayBorrow(address, uint256) external;
    
    function aaveSwapBorrowRateMode(address) external;
}
