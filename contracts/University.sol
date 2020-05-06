pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
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

    //TODO: resolve students and classrooms addresses using ENS

    //Uniswap Config
    address _uniswapWETH;
    address _uniswapDAI;
    IUniswapV2Router01 public _uniswapRouter;

    //Compound Config
    CERC20 public cDAI;
    IComptroller public comptroller;
    IPriceOracle public priceOracle;

    IERC20 public daiToken;
    IRelayHub public relayHub;
    IClassroomFactory _classroomFactory;
    IStudentFactory _studentFactory;
    address _studentApplicationFactoryAddress;

    constructor(
        bytes32 _name,
        uint24 _cut,
        uint256 studentGSNDeposit,
        address daiAddress,
        address relayHubAddress,
        address classroomFactoryAddress,
        address studentFactoryAddress,
        address studentApplicationFactoryAddress
    ) public {
        name = _name;
        cut = _cut;
        _studentGSNDeposit = studentGSNDeposit;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(READ_STUDENT_LIST_ROLE, _msgSender());
        daiToken = IERC20(daiAddress);
        relayHub = IRelayHub(relayHubAddress);
        _classroomFactory = IClassroomFactory(classroomFactoryAddress);
        _studentFactory = IStudentFactory(studentFactoryAddress);
        _studentApplicationFactoryAddress = studentApplicationFactoryAddress;
    }

    receive() external payable {
        emit LogReceived(msg.sender, msg.value);
    }

    event LogNewClassroom(bytes32, address);
    event LogChangeName(bytes32);
    event LogChangeCut(uint24);
    event LogReceived(address, uint256);

    function configureCompound(
        address compoundDAIAddress,
        address comptrollerAddress,
        address priceOracleAddress
    ) public onlyOwner {
        cDAI = CERC20(compoundDAIAddress);
        comptroller = IComptroller(comptrollerAddress);
        priceOracle = IPriceOracle(priceOracleAddress);
    }

    function configureUniswap(
        address uniswapWETH,
        address uniswapDAI,
        address uniswapRouter
    ) public onlyOwner {
        _uniswapWETH = uniswapWETH;
        _uniswapDAI = uniswapDAI;
        _uniswapRouter = IUniswapV2Router01(uniswapRouter);
    }

    function changeName(bytes32 val) public onlyOwner {
        name = val;
        emit LogChangeName(name);
    }

    function changeCut(uint24 val) public onlyOwner {
        cut = val;
        emit LogChangeCut(cut);
    }

    function changeStudentGSNDeposit(uint256 val) public onlyOwner {
        _studentGSNDeposit = val;
    }

    function availableFunds() public view override returns (uint256) {
        uint256 funds = daiToken.balanceOf(address(this));
        if (funds < endowmentLocked.add(operationalBudget)) return 0;
        return funds.sub(endowmentLocked).sub(operationalBudget);
    }

    function isValidClassroom(address classroom) public view override returns (bool) {
        return hasRole(CLASSROOM_PROFESSOR_ROLE, classroom);
    }

    function studentIsRegistered(address student) public view override returns (bool) {
        require(
            hasRole(READ_STUDENT_LIST_ROLE, _msgSender()),
            "University: caller doesn't have READ_STUDENT_LIST_ROLE"
        );
        return hasRole(STUDENT_IDENTITY_ROLE, student);
    }

    function viewMyApplications() public view override returns (address[] memory) {
        return viewStudentApplications(_msgSender());
    }

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

    function studentSelfRegisterGSN(bytes32 sName) public returns (address) {
        address student = _newStudent(sName, _msgSenderGSN());
        relayHub.depositFor.value(_studentGSNDeposit)(student);
        return student;
    }

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

    //ex: owner, name, 0.2 * 10**6, 0.5 * 10**6, 0, 50 * (10 ** 18), 30 days, challengeAddress
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

    function addStudentScore(address student, int32 val) public override {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        IStudent(student).addScore(val);
    }

    function subStudentScore(address student, int32 val) public override {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        IStudent(student).subScore(val);
    }

    function applyFundsCompound(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        TransferHelper.safeApprove(address(daiToken), address(cDAI), val);
        cDAI.mint(val);
    }

    function enterCompoundDAIMarket() public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cDAI);
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        if (errors[0] != 0) {
            revert("University: Comptroller.enterMarkets failed.");
        }
    }

    function exitCompoundDAIMarket() public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        uint256 error = comptroller.exitMarket(address(cDAI));
        if (error != 0) {
            revert("University: Comptroller.exitMarket failed.");
        }
    }

    function getCompoundLiquidityAndShortfall() 
        public 
        view 
        override
        returns (uint256, uint256) {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        (uint256 error, uint256 liquidity, uint256 shortfall) = 
            comptroller
            .getAccountLiquidity(address(this));
        if (error != 0) {
            revert("University: Comptroller.getAccountLiquidity failed.");
        }
        return (liquidity, shortfall);
    }

    function getCompoundPriceInWEI(address cToken) 
        public 
        view 
        override
        returns (uint256) {
        return priceOracle.getUnderlyingPrice(cToken);
    }

    function getCompoundMaxBorrowInWEI(address cToken) 
        public 
        view 
        override
        returns (uint256) {
        (uint256 liquidity, ) = getCompoundLiquidityAndShortfall();
        return liquidity.div(priceOracle.getUnderlyingPrice(cToken));
    }

    function compoundBorrow(address cToken, uint256 val) 
        public 
        override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        CERC20(cToken).borrow(val);
    }

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

    function recoverFundsCompound(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        cDAI.redeemUnderlying(val);
    }

    function increaseOperationalBudget(uint256 val) public onlyOwner {
        require(
            endowmentLocked >= val,
            "University: not enough endowment"
        );
        operationalBudget = operationalBudget.add(val);
        endowmentLocked = endowmentLocked.sub(val);
    }

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

    function viewAllStudentsFromGrantManager(
            address grantsManager
        ) public returns (address[] memory) {
        require(
            hasRole(UNIVERSITY_OVERSEER_ROLE, _msgSender()),
            "University: caller doesn't have UNIVERSITY_OVERSEER_ROLE"
        );
        return IGrantsManager(grantsManager).viewAllStudents();
    }

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

    function refillUniversityRelayer(uint256 val) public {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()) || _msgSender() == owner(),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        relayHub.depositFor.value(val)(address(this));
    }

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

    // This function is vulnerable to sandwich attacks. Since the very nature of this function is for a donor to donate money, it is not needed to prevent the donor from manipulating its own donation
    function donateETH(uint256 donation) public payable override {
        uint256[] memory amounts = swapETH_DAI(donation, 12 hours);
        donators[_msgSender()] = donators[_msgSender()].add(amounts[1]);
        accountDonation(amounts[1]);
    }

    function donateDAI(uint256 donation) public override {
        TransferHelper.safeTransferFrom(
            address(daiToken),
            _msgSender(),
            address(this),
            donation
        );
        donators[_msgSender()] = donators[_msgSender()].add(donation);
        accountDonation(donation);
    }

    function accountDonation(uint256 donation) internal {
        donationsReceived = donationsReceived.add(donation);
        endowmentLocked = endowmentLocked.add(donation);
    }

    function accountRevenue(uint256 revenue) public override {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        revenueReceived = revenueReceived.add(revenue);
        endowmentLocked = endowmentLocked.add(revenue);
    }

    function accountReturns(uint256 financialReturns) internal {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        returnsReceived = revenueReceived.add(financialReturns);
        endowmentLocked = endowmentLocked.add(financialReturns);
    }


    //TODO: implement funds manager
}
