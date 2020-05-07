pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IUniversity.sol";


contract ExampleFundsManager is Ownable {
    using SafeMath for uint256;

    IUniversity public university;
    uint256 _saveDAIForGrants;
    uint24 _compoundRatio;

    constructor(address universityAddress) public {
        university = IUniversity(universityAddress);
        _saveDAIForGrants = 1000 * 1e18;
        _compoundRatio = 0.5 * 1e6;
    }

    function changeSaveDai(uint256 val) public onlyOwner {
        _saveDAIForGrants = val;
    }

    function changeRatio(uint24 val) public onlyOwner {
        require(val <= 1e6, "Classroom: can't be more that 100% in ppm");
        _compoundRatio = val;
    }

    function triggerUpdate() public onlyOwner {
        uint256 funds = university.availableFundsForInvestment();
        if (funds < _saveDAIForGrants) redeem(_saveDAIForGrants.sub(funds));
        else if (funds.sub(_saveDAIForGrants) > 10 * 1e18)
            invest(funds.sub(_saveDAIForGrants));
    }

    function redeem(uint256 val) internal {
        uint256 compoundRedeem = val.mul(_compoundRatio).div(1e6);
        university.recoverFundsCompound(compoundRedeem);
        university.recoverFundsAave(val.sub(compoundRedeem));
    }

    function invest(uint256 val) internal {
        uint256 compoundApply = val.mul(_compoundRatio).div(1e6);
        university.applyFundsCompound(compoundApply);
        university.applyFundsAave(val.sub(compoundApply));
    }
}
