pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interface/Aave/aToken.sol";
import "./interface/Aave/ILendingPool.sol";
import "./interface/Aave/ILendingPoolAddressesProvider.sol";
import "./gambi/BaseRelayRecipient.sol";
import "./gambi/GSNTypes.sol";
import "./gambi/IRelayHub.sol";
import "./interface/IClassroom.sol";
import "./interface/IStudent.sol";
import "./interface/IStudentApplication.sol";
import "./interface/IClassroomFactory.sol";
import "./interface/IStudentFactory.sol";
import "./interface/IStudentApplicationFactory.sol";
import "./interface/IUniversity.sol";
import "./interface/IGrantsManager.sol";
import "./MyUtils.sol";

//TODO: Natspec Document ENVERYTHING
//TODO: Sort function order from all contracts
//TODO: Divide University in smaller contracts

contract University is Ownable, AccessControl, BaseRelayRecipient, IUniversity {
    using SafeMath for uint256;

    //CLASSLIST_ADMIN_ROLE can add new manually created classes to the list
    bytes32 public constant CLASSLIST_ADMIN_ROLE = keccak256(
        "CLASSLIST_ADMIN_ROLE"
    );
    // FUNDS_MANAGER_ROLE can withdraw funds from the contract
    bytes32 public constant FUNDS_MANAGER_ROLE = keccak256(
        "FUNDS_MANAGER_ROLE"
    );
    // GRANTS_MANAGER_ROLE can approve/decline grant claims
    bytes32 public constant GRANTS_MANAGER_ROLE = keccak256(
        "GRANTS_MANAGER_ROLE"
    );
    // READ_STUDENT_LIST_ROLE allow reading students list
    bytes32 public constant READ_STUDENT_LIST_ROLE = keccak256(
        "READ_STUDENT_LIST_ROLE"
    );
    /// STUDENT_IDENTITY_ROLE allow asking for grants and requesting a classroom from a successful application
    bytes32 public constant STUDENT_IDENTITY_ROLE = keccak256(
        "STUDENT_IDENTITY_ROLE"
    );
    /// CLASSROOM_PROFESSOR_ROLE can manage itself inside the University and registering student applications
    bytes32 public constant CLASSROOM_PROFESSOR_ROLE = keccak256(
        "CLASSROOM_PROFESSOR_ROLE"
    );
    /// UNIVERSITY_OVERSEER_ROLE can inspect Grant Managers and Fund Managers, and present cases for funders to vote upon
    bytes32 public constant UNIVERSITY_OVERSEER_ROLE = keccak256(
        "UNIVERSITY_OVERSEER_ROLE"
    );/// REGISTERED_SUPPLIER_ROLE can receive transactions to consume the operational budget
    bytes32 public constant REGISTERED_SUPPLIER_ROLE = keccak256(
        "REGISTERED_SUPPLIER_ROLE"
    );

    // Parameter: Name of this University
    bytes32 public override name;
    // Parameter: University cut from professor (Parts per Million)
    uint24 public override cut;
    // Parameter: GSN funds to give students
    uint256 _studentGSNDeposit;
    // List of every registered classroom
    address[] public _classList;
    // List of every student
    address[] _students;
    // Mapping of each student's applications
    mapping(address => address[]) _studentApplicationsMapping;
    // Mapping of every donor and donations
    mapping(address => uint256) public donators;
    // Total amount of donations received so far
    uint256 public donationsReceived;
    // Total amount of operational revenue received so far
    uint256 public revenueReceived;
    // Total amount of financial returns received so far
    uint256 public returnsReceived;
    // Total amount of endowment locked in the fund
    uint256 public endowmentLocked;
    // Total amount of funds allowed for expenses
    uint256 public operationalBudget;

    //Uniswap Config
    address _uniswapWETH;
    address _uniswapDAI;
    IUniswapV2Router01 public _uniswapRouter;

    //Compound Config
    CERC20 public cDAI;
    IComptroller public comptroller;
    IPriceOracle public priceOracle;

    //Aave Config
    ILendingPoolAddressesProvider _aaveProvider;
    ILendingPool _aaveLendingPool;
    address _aaveLendingPoolCore;
    address _aTokenDAI;

    //Tokens
    IERC20 public daiToken;

    //GSN
    IRelayHub public relayHub;

    //Factory
    IClassroomFactory _classroomFactory;
    IStudentFactory _studentFactory;
    address _studentApplicationFactoryAddress;

    /// @notice Constructor setup the basic variables
    /// @dev Not all variables can be defined in this constructor because the limitation of the stack size
    /// @param name_ Given name for the university
    /// @param cut_ Cut from professor payments, in PPM
    /// @param studentGSNDeposit Ammount of ETH to give relayer hub of students for UX reasons, in WEI
    /// @param daiAddress Adress of contract in the network
    /// @param relayHubAddress Adress of contract in the network
    /// @param classroomFactoryAddress Adress of contract in the network
    /// @param studentFactoryAddress Adress of contract in the network
    /// @param studentApplicationFactoryAddress Adress of contract in the network
    constructor(
        bytes32 name_,
        uint24 cut_,
        uint256 studentGSNDeposit,
        address daiAddress,
        address relayHubAddress,
        address classroomFactoryAddress,
        address studentFactoryAddress,
        address studentApplicationFactoryAddress
    ) public {
        name = name_;
        cut = cut_;
        _studentGSNDeposit = studentGSNDeposit;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(READ_STUDENT_LIST_ROLE, _msgSender());
        daiToken = IERC20(daiAddress);
        relayHub = IRelayHub(relayHubAddress);
        _classroomFactory = IClassroomFactory(classroomFactoryAddress);
        _studentFactory = IStudentFactory(studentFactoryAddress);
        _studentApplicationFactoryAddress = studentApplicationFactoryAddress;
    }

    /// @notice Allow receiving ETH
    receive() external payable {
        emit LogReceived(msg.sender, msg.value);
    }

    /// @notice Allow taking ETH from the contract
    function withdraw(uint256 val) public onlyOwner {
        TransferHelper.safeTransferETH(_msgSender(), val);
    }

    /// @notice Records the name and address of every new classroom created
    event LogNewClassroom(bytes32, address);
    /// @notice Records the name changes of this University
    event LogChangeName(bytes32);
    /// @notice Records the changes in the Cut parameter
    event LogChangeCut(uint24);
    /// @notice Records ETH received
    event LogReceived(address, uint256);
    /// @notice Records donations received and the address of the donor
    event LogDonation(address, uint256);
    /// @notice Records investment returns received and the address of the caller
    event LogReturn(address, uint256);
    /// @notice Records revenues received and the address of the souce
    event LogRevenue(address, uint256);

    /// @notice Setup the Compound variables
    /// @dev Not all variables can be defined in the constructor because the limitation of the stack size
    /// @param compoundDAIAddress Address of the contract in the network
    /// @param comptrollerAddress Address of the contract in the network
    /// @param priceOracleAddress Address of the contract in the network
    function configureCompound(
        address compoundDAIAddress,
        address comptrollerAddress,
        address priceOracleAddress
    ) public onlyOwner {
        cDAI = CERC20(compoundDAIAddress);
        comptroller = IComptroller(comptrollerAddress);
        priceOracle = IPriceOracle(priceOracleAddress);
    }

    /// @notice Setup the Uniswap variables
    /// @dev Not all variables can be defined in the constructor because the limitation of the stack size
    /// @param uniswapWETH Address of the contract in the network
    /// @param uniswapDAI Address of the contract in the network
    /// @param uniswapRouter Address of the contract in the network
    function configureUniswap(
        address uniswapWETH,
        address uniswapDAI,
        address uniswapRouter
    ) public onlyOwner {
        _uniswapWETH = uniswapWETH;
        _uniswapDAI = uniswapDAI;
        _uniswapRouter = IUniswapV2Router01(uniswapRouter);
    }

    /// @notice Setup the Ava variables
    /// @dev Not all variables can be defined in the constructor because the limitation of the stack size
    /// @param lendingPoolAddressesProvider Address of the contract in the network
    function configureAave(
        address lendingPoolAddressesProvider
    ) public onlyOwner {
        _aaveProvider = ILendingPoolAddressesProvider(lendingPoolAddressesProvider);
        _aaveLendingPool = ILendingPool(_aaveProvider.getLendingPool());
        _aaveLendingPoolCore = _aaveProvider.getLendingPoolCore();
        _aTokenDAI = ILendingPoolCore(_aaveLendingPoolCore)
            .getReserveATokenAddress(address(daiToken));
    }

    /// @notice Change the name of the University
    /// @param val New value
    function changeName(bytes32 val) public onlyOwner {
        name = val;
        emit LogChangeName(name);
    }

    /// @notice Change the cut charged from the professors
    /// @param val New value, in PPM
    function changeCut(uint24 val) public onlyOwner {
        cut = val;
        emit LogChangeCut(cut);
    }

    /// @notice Change the value of ETH deposited in students relay hub
    /// @param val New value, in WEI
    function changeStudentGSNDeposit(uint256 val) public onlyOwner {
        _studentGSNDeposit = val;
    }

    /// @return the ammount of DAI able for investing
    function availableFundsForInvestment() public view override returns (uint256) {
        uint256 funds = daiToken.balanceOf(address(this));
        if (funds < operationalBudget) return 0;
        return funds.sub(operationalBudget);
    }

    /// @return the ammount of DAI able for giving grants
    function availableFunds() public view override returns (uint256) {
        uint256 funds = daiToken.balanceOf(address(this));
        if (funds < endowmentLocked.add(operationalBudget)) return 0;
        return funds.sub(endowmentLocked).sub(operationalBudget);
    }

    /// @return true if the classroom is registered in this University 
    function isValidClassroom(address classroom) public view override returns (bool) {
        return hasRole(CLASSROOM_PROFESSOR_ROLE, classroom);
    }

    /// @return true if the student is registered in this University 
    function studentIsRegistered(address student) public view override returns (bool) {
        require(
            hasRole(READ_STUDENT_LIST_ROLE, _msgSender()),
            "University: caller doesn't have READ_STUDENT_LIST_ROLE"
        );
        return hasRole(STUDENT_IDENTITY_ROLE, student);
    }

    /// @return the address of the application of a Student
    function viewMyApplications() public view override returns (address[] memory) {
        return viewStudentApplications(_msgSender());
    }

    /// @param addr Address of the student
    /// @return the addresses of the applications of a the supplied address
    function viewStudentApplications(address addr)
        public
        view
        override
        returns (address[] memory)
    {
        require(
            addr == _msgSender() || hasRole(GRANTS_MANAGER_ROLE, _msgSender()),
            "Classroom: read permission denied"
        );
        return _studentApplicationsMapping[addr];
    }

    /// @notice Self-register function where an address can create an instance of a Student in this University
    /// @dev This GSN implementation is buggy
    /// @param sName Name of the Student
    /// @return the smart contract address for this Student instance in this University
    function studentSelfRegisterGSN(bytes32 sName) public returns (address) {
        address student = _newStudent(sName, _msgSenderGSN());
        relayHub.depositFor.value(_studentGSNDeposit)(student);
        return student;
    }

    /// @notice Self-register function where an address can create an instance of a Student in this University
    /// @param sName Name of the Student
    /// @return the smart contract address for this Student instance in this University
    function studentSelfRegister(bytes32 sName) public returns (address) {
        return _newStudent(sName, _msgSender());
    }

    function _newStudent(bytes32 sName, address caller)
        internal
        returns (address)
    {
        require(
            _studentApplicationsMapping[_msgSenderGSN()].length == 0,
            "University: student already registered"
        );
        //Gambiarra: Push address(0) in the mapping to mark that student as registered in the university
        _studentApplicationsMapping[caller].push(address(0));
        address student = _studentFactory.newStudent(sName, address(this));
        IStudent(student).transferOwnershipStudent(caller);
        address studentAddr = address(student);
        _students.push(studentAddr);
        grantRole(STUDENT_IDENTITY_ROLE, studentAddr);
        return address(studentAddr);
    }

    /// @notice Register function where an Admin can can create an instance of a Classroom in this University
    /// @param owner Address to own this classroom
    /// @param cName Name this classroom
    /// @param cCut Cut of the principal amount deposited that is charged from students, in PPM
    /// @param cPCut Cut of the pooled returns from successful students, in PPM
    /// @param minScore Minimum score value required from students to be able to apply in this classroom
    /// @param entryPrice Required deposit to be applied as principal an locked for the duration of the course, in decimal units of DAI
    /// @param duration Lock time between course opening and closing, in Timestamp
    /// @param challengeAddress Address to the challenge to be solved in this Classroom's courses
    /// @return the smart contract address for this Classroom instance in this University
    function newClassRoom(
        address owner,
        bytes32 cName,
        uint24 cCut,
        uint24 cPCut,
        int32 minScore,
        uint256 entryPrice,
        uint256 duration,
        address challengeAddress
    ) public returns (address) {
        require(
            hasRole(CLASSLIST_ADMIN_ROLE, _msgSender()),
            "University: caller doesn't have CLASSLIST_ADMIN_ROLE"
        );
        return
            _newClassRoom(
                owner,
                cName,
                cCut,
                cPCut,
                minScore,
                entryPrice,
                duration,
                challengeAddress
            );
    }

    function _newClassRoom(
        address owner,
        bytes32 cName,
        uint24 cCut,
        uint24 cPCut,
        int32 minScore,
        uint256 entryPrice,
        uint256 duration,
        address challengeAddress
    ) internal returns (address) {
        address classroom = _classroomFactory.newClassroom(
            cName,
            cCut,
            cPCut,
            minScore,
            entryPrice,
            duration,
            payable (address(this)),
            challengeAddress,
            address(daiToken),
            address(cDAI),
            _studentApplicationFactoryAddress
        );
        IClassroom(classroom).transferOwnershipClassroom(owner);
        address classroomAddr = address(classroom);
        _classList.push(classroomAddr);
        grantRole(READ_STUDENT_LIST_ROLE, classroomAddr);
        grantRole(CLASSROOM_PROFESSOR_ROLE, classroomAddr);
        emit LogNewClassroom(cName, classroomAddr);
        return classroomAddr;
    }

    /// @notice Register function where an Student can can create an instance of a Classroom in this University, upon being successful in any classroom
    /// @param applicationAddr Address of the successful application
    /// @param cName Name this classroom
    /// @param cCut Cut of the principal amount deposited that is charged from students, in PPM
    /// @param cPCut Cut of the pooled returns from successful students, in PPM
    /// @param minScore Minimum score value required from students to be able to apply in this classroom
    /// @param entryPrice Required deposit to be applied as principal an locked for the duration of the course, in decimal units of DAI
    /// @param duration Lock time between course opening and closing, in Timestamp
    /// @param challenge Address to the challenge to be solved in this Classroom's courses
    /// @return the smart contract address for this Classroom instance in this University
    function studentRequestClassroom(
        address applicationAddr,
        bytes32 cName,
        uint24 cCut,
        uint24 cPCut,
        int32 minScore,
        uint256 entryPrice,
        uint256 duration,
        address challenge
    ) public override returns (address) {
        require(
            hasRole(STUDENT_IDENTITY_ROLE, _msgSender()),
            "University: caller doesn't have STUDENT_IDENTITY_ROLE"
        );
        require(
            checkForStudentApplication(_msgSender(), applicationAddr),
            "University: caller is not student of this application"
        );
        IStudentApplication application = IStudentApplication(applicationAddr);
        require(
            application.applicationState() == 3,
            "University: application is not successful"
        );
        return
            _newClassRoom(
                IStudent(_msgSender()).ownerStudent(),
                cName,
                cCut,
                cPCut,
                minScore,
                entryPrice,
                duration,
                challenge
            );
    }

    /// @notice Register and map a Student's application to this Student
    /// @param student Address of the Student
    /// @param application Address of the application
    function registerStudentApplication(
        address student,
        address application
    ) public override
    {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        _studentApplicationsMapping[student].push(application);
    }

    /// @notice Check if an application belongs to a specific Student
    /// @param studentAddress Address of the Student
    /// @param applicationAddress Address of the application
    /// @return true if the application belongs to the Student
    function checkForStudentApplication(
        address studentAddress,
        address applicationAddress
    ) internal view returns (bool) {
        for (
            uint256 i = 0;
            i < _studentApplicationsMapping[studentAddress].length;
            i++
        ) {
            if (
                _studentApplicationsMapping[studentAddress][i] ==
                applicationAddress
            ) return true;
        }
        return false;
    }

    /// @notice Increase a Student's score upon successful application
    /// @param student Address of the Student
    /// @param val Value to be added
    function addStudentScore(address student, int32 val) public override {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        IStudent(student).addScore(val);
    }

    /// @notice Decrease a Student's score upon failed application
    /// @param student Address of the Student
    /// @param val Value to be subtracted
    function subStudentScore(address student, int32 val) public override {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        IStudent(student).subScore(val);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function applyFundsCompound(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        TransferHelper.safeApprove(address(daiToken), address(cDAI), val);
        cDAI.mint(val);
    }

    /// @notice Get the ammount of DAI applied in Compound
    /// @return ammount of DAI applied in Compound
    function appliedDAICompound() public view override returns (uint256) {
        return cDAI.balanceOfUnderlying(address(this));
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function recoverFundsCompound(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        cDAI.redeemUnderlying(val);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function applyFundsAave(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        TransferHelper.safeApprove(address(daiToken), _aaveLendingPoolCore, val);
        _aaveLendingPool.deposit(address(daiToken), val, 0);
    }

    /// @notice Get the ammount of DAI applied in Aave
    /// @return ammount of DAI applied in Aave
    function appliedDAIAave() public view override returns (uint256) {
        return aToken(_aTokenDAI).balanceOf(address(this));
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function recoverFundsAave(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        aToken(_aTokenDAI).redeem(val);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function setAaveMarketCollateralForDAI(bool state) public override {
        setAaveMarketCollateral(address(daiToken), state);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function setAaveMarketCollateral(address token, bool state) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        _aaveLendingPool.setUserUseReserveAsCollateral(token, state);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function enterCompoundDAIMarket() public override {
        enterCompoundMarket(address(cDAI));
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function enterCompoundMarket(address token) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        address[] memory cTokens = new address[](1);
        cTokens[0] = token;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        if (errors[0] != 0) {
            revert("University: Comptroller.enterMarkets failed.");
        }
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function exitCompoundDAIMarket() public override {
        exitCompoundMarket(address(cDAI));
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function exitCompoundMarket(address token) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        uint256 error = comptroller.exitMarket(token);
        if (error != 0) {
            revert("University: Comptroller.exitMarket failed.");
        }
    }

    /// @notice Get the liquidity state in Compound
    /// @return liquidity and/or shortfall in ETH, expressed in WEI
    function getCompoundLiquidityAndShortfall() 
        public 
        view 
        override
        returns (uint256, uint256) {
        (uint256 error, uint256 liquidity, uint256 shortfall) = 
            comptroller
            .getAccountLiquidity(address(this));
        if (error != 0) {
            revert("University: Comptroller.getAccountLiquidity failed.");
        }
        return (liquidity, shortfall);
    }

    /// @notice Get the price from a specific token in Compound
    /// @param cToken Compound token address to query
    /// @return price in ETH, expressed in WEI
    function getCompoundPriceInWEI(address cToken) 
        public 
        view 
        override
        returns (uint256) {
        return priceOracle.getUnderlyingPrice(cToken);
    }

    /// @notice Get the maximum volume of tokens to borrow in Compound
    /// @param cToken Compound token address to query
    /// @return maximum borrow volume, expressed in WEI
    /// @dev Borrowing the maximum amount may lead to intant liquidation. Always borrow less than the maximum
    function getCompoundMaxBorrowInWEI(address cToken) 
        public 
        view 
        override
        returns (uint256) {
        (uint256 liquidity, ) = getCompoundLiquidityAndShortfall();
        return liquidity.div(priceOracle.getUnderlyingPrice(cToken));
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function compoundBorrow(address cToken, uint256 val) 
        public 
        override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        CERC20(cToken).borrow(val);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function compoundGetBorrow(address cToken) 
        public 
        view 
        override
        returns (uint256) {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        return CERC20(cToken).borrowBalanceCurrent(address(this));
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function compoundRepayBorrow(address token, address cToken, uint256 val)
        public 
        override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        require(
            IERC20(token).balanceOf(address(this)) >= val,
            "University: not enough of this token stored"
        );
        TransferHelper.safeApprove(token, cToken, val);
        CERC20(cToken).repayBorrow(val);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function aaveGetBorrow(address token, uint256 val, bool variableRate) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        uint8 vRate = variableRate ? 2 : 1;
        _aaveLendingPool.borrow(token, val, vRate, 0);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function aaveRepayBorrow(address token, uint256 val)
        public 
        override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        require(
            IERC20(token).balanceOf(address(this)) >= val,
            "University: not enough of this token stored"
        );
        TransferHelper.safeApprove(token, _aaveProvider.getLendingPoolCore(), val);
        _aaveLendingPool.repay(token, val, address(this));
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function aaveSwapBorrowRateMode(address token) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        _aaveLendingPool.swapBorrowRateMode(token);
    }

    /// @notice Allow managing how much Funds Manager can draw from funds to cover operational expenses. Must be called from the university admin
    /// @param val Value to increase
    function increaseOperationalBudget(uint256 val) public onlyOwner {
        require(
            endowmentLocked >= val,
            "University: not enough endowment"
        );
        operationalBudget = operationalBudget.add(val);
        endowmentLocked = endowmentLocked.sub(val);
    }

    /// @notice Allow managing how much Funds Manager can draw from funds to cover operational expenses. Must be called from the university admin
    /// @param val Value to decrease
    function decreaseOperationalBudget(uint256 val) public onlyOwner {
        require(
            operationalBudget >= val,
            "University: not enough budget to decrease"
        );
        operationalBudget = operationalBudget.sub(val);
        endowmentLocked = endowmentLocked.add(val);
    }

    /// @notice Allow a Funds Manager to send funds to Registered Suppliers, spending the operational budget set by the University owner
    /// @param to Address of the Registered Supplier
    /// @param val Value to be sent, in DAI decimals
    function spendBudget(address to, uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        require(
            hasRole(REGISTERED_SUPPLIER_ROLE, to),
            "University: receiver doesn't have REGISTERED_SUPPLIER_ROLE"
        );
        require(
            operationalBudget >= val,
            "University: not enough operational budget"
        );
        require(
            daiToken.balanceOf(address(this)) >= val,
            "University: liquidate some positions first"
        );
        TransferHelper.safeTransfer(address(daiToken), to, val);
        operationalBudget = operationalBudget.sub(val);
    }

    /// @notice Allow a Grants Manager to pay a Student's entry price for an application, if the appointed Grants Manager decide so
    /// @param studentApplication Address of the Student
    /// @param price Value of the application's entry price
    function giveGrant(address studentApplication, uint256 price) public override {
        require(
            hasRole(GRANTS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have GRANTS_MANAGER_ROLE"
        );
        require(
            availableFunds() >= price,
            "University: not enough available funds"
        );
        IStudentApplication(studentApplication).payEntryPrice();
    }

    /// @notice Allow a Funds Manager to redirect surplus funds from liquidated positions to the endowment locked value. Irreversible
    /// @param val Value to be sent, in DAI decimals
    function reinvestReturns(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        require(
            availableFunds() >= val,
            "University: not enough available funds"
        );
        accountReturns(val);
    }

    /// @notice Allow an appointed Overseer to inspect all students that received grants by a specific Grants Manager
    /// @param grantsManager Address of the Grants Manager
    /// @return array of Students addresses
    function viewAllStudentsFromGrantManager(
            address grantsManager
        ) public returns (address[] memory) {
        require(
            hasRole(UNIVERSITY_OVERSEER_ROLE, _msgSender()),
            "University: caller doesn't have UNIVERSITY_OVERSEER_ROLE"
        );
        return IGrantsManager(grantsManager).viewAllStudents();
    }

    /// @notice Allow an appointed Overseer to inspect all grants issued by a specific Grants Manager to a specific Student
    /// @param student Address of the Student
    /// @param grantsManager Address of the Grants Manager
    /// @return array of grant values
    function viewAllStudentGrantsFromGrantManager(
            address student, 
            address grantsManager
        ) public returns (uint256[] memory) {
        require(
            hasRole(UNIVERSITY_OVERSEER_ROLE, _msgSender()),
            "University: caller doesn't have UNIVERSITY_OVERSEER_ROLE"
        );
        return IGrantsManager(grantsManager).viewAllGrantsForStudent(student);
    }

    /// @notice GSN specific implementation
    /// @dev The idea here is only to allow GSN interactions with one specific funcion
    function acceptRelayedCall(
        GSNTypes.RelayRequest calldata relayRequest,
        bytes calldata,
        uint256
    ) external pure returns (bytes memory context) {
        require(
            MyUtils.readBytes4(relayRequest.encodedFunction, 0) ==
                this.studentSelfRegisterGSN.selector,
            "University: GSN not enabled for this function"
        );
        return abi.encode(relayRequest.target, 0);
    }

    /// @notice Allow a Funds Manager to refill the GSN relayer using the University ETH funds
    /// @param val Value to be deposited in the relayer, in WEI
    function refillUniversityRelayer(uint256 val) public {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()) || _msgSender() == owner(),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        relayHub.depositFor.value(val)(address(this));
    }

    /// @notice Allow a Funds Manager to swap University funds in DAI for ETH using Uniswap
    /// @dev The logic for controlling slippage and price should be taken care by the Funds Manager
    /// @param amount amount of DAI to trade, in decimals
    /// @param deadline timestamps to keep the transaction valid before reverting 
    function swapDAI_ETH(
        uint256 amount,
        uint256 deadline
    ) public override returns (uint[] memory amounts) {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        require(
            _uniswapWETH != address(0),
            "University: setup uniswap first"
        );
        amounts = swapBlind(_uniswapDAI, _uniswapWETH, amount, deadline);
    }

    /// @notice Allow a Funds Manager to swap University funds in ETH for DAI using Uniswap
    /// @dev The logic for controlling slippage and price should be taken care by the Funds Manager
    /// @param amount amount of ETH to trade, in decimals of WETH
    /// @param deadline timestamps to keep the transaction valid before reverting 
    function swapETH_DAI(
        uint256 amount,
        uint256 deadline
    ) public override returns (uint[] memory amounts) {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        require(
            _uniswapWETH != address(0),
            "University: setup uniswap first"
        );
        amounts = swapBlind(_uniswapWETH, _uniswapDAI, amount, deadline);
    }

    function swapBlind(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 deadline
    ) internal returns (uint[] memory amounts) {
        TransferHelper.safeApprove(tokenA, address(_uniswapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        amounts = _uniswapRouter.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            deadline
        );
    }
    
    /// @notice Allow donating ETH to the University funds
    /// @dev This function is vulnerable to sandwich attacks. Since the very nature of this function is for a donor to donate money, it is not needed to prevent the donor from manipulating its own donation
    /// @param donation amount of ETH to donate, in WEI
    function donateETH(uint256 donation) public payable override {
        uint256[] memory amounts = swapETH_DAI(donation, 12 hours);
        accountDonation(_msgSender(), amounts[1]);
    }

    /// @notice Allow donating DAI to the University funds. Require allowing the University first
    /// @param donation amount of DAI to donate, in decimals
    function donateDAI(uint256 donation) public override {
        TransferHelper.safeTransferFrom(
            address(daiToken),
            _msgSender(),
            address(this),
            donation
        );
        accountDonation(_msgSender(), donation);
    }

    function accountDonation(address sender, uint256 donation) internal {
        donationsReceived = donationsReceived.add(donation);
        endowmentLocked = endowmentLocked.add(donation);
        donators[sender] = donators[sender].add(donation);
        LogDonation(_msgSender(), donation);
    }
    
    /// @notice Classroom call to account a revenue received from a completed course
    function accountRevenue(uint256 revenue) public override {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        revenueReceived = revenueReceived.add(revenue);
        endowmentLocked = endowmentLocked.add(revenue);
        LogRevenue(_msgSender(), revenue);
    }

    function accountReturns(uint256 financialReturns) internal {
        returnsReceived = revenueReceived.add(financialReturns);
        endowmentLocked = endowmentLocked.add(financialReturns);
        LogReturn(_msgSender(), financialReturns);
    }
}
