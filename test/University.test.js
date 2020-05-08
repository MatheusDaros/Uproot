var web3 = require('web3');

require('dotenv').config();

const Assert = require('truffle-assertions');
const Artifact = artifacts.require("University");

//TODO library and require
function getAddress(file) {
  let input = require(file);
  let dKey = Object.keys(input.networks)[0];
  return input.networks[dKey].address;
}

//University Params
const name = web3.utils.fromAscii(process.env.UNIVERSITY_NAME);
const cut = web3.utils.fromAscii(process.env.UNIVERSITY_CUT);
const studentGSNDeposit = web3.utils.fromAscii(process.env.UNIVERSITY_GSNDEPOSIT);
const relayHubAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"; //getAddress('../build/contracts/CERC20.json');
const classroomFactoryAddress = getAddress('../build/contracts/ClassroomFactory.json');
const studentFactoryAddress = getAddress('../build/contracts/StudentFactory.json');
const studentApplicationFactoryAddress = getAddress('../build/contracts/StudentApplicationFactory.json');
const daiAddress = getAddress('../build/contracts/ERC20.json');

contract('University', accounts => {

  let contractInstance;
  const ownerAddress = accounts[0];
  const student1Address = accounts[1];
  const student2Address = accounts[2];

  /*
  before(async () => {
    web3.eth.defaultAccount = ownerAddress;
  });
  */

  beforeEach(async () => {
    contractInstance = await Artifact.new(name, cut, studentGSNDeposit, relayHubAddress, classroomFactoryAddress, studentFactoryAddress, studentApplicationFactoryAddress, daiAddress);
  });

  describe("constructor", () => {
    it("must register owner at deploy", async () => {
      const result = await Assert.createTransactionResult(
        contractInstance,
        contractInstance.transactionHash
      );
      Assert.eventEmitted(result, "OwnershipTransferred");
    });
    it("must register owner as Role Grant at deploy", async () => {
      const result = await Assert.createTransactionResult(
        contractInstance,
        contractInstance.transactionHash
      );
      Assert.eventEmitted(result, "RoleGranted");
    });
    it('1 - Deploying contract properly...', async () => {
      assert(Artifact.address != '');
    });
  });

  /*
  describe("configureCompound", () => {
    it('success', async () => {
      const compoundDAIAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
      const comptrollerAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
      const priceOracleAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
      await contractInstance.configureCompound(compoundDAIAddress, comptrollerAddress, priceOracleAddress, { from: ownerAddress });
      const result = await contractInstance.CERC20();
      assert.equal(result, compoundDAIAddress, 'wrong Compund DAI address');
    });
  });

  describe("configureUniswap", () => {
    it('success', async () => {
      const uniswapWETH = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
      const uniswapDAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
      const uniswapRouter = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
      await contractInstance.configureUniswap(uniswapWETH, uniswapDAI, uniswapRouter, { from: ownerAddress });
      const result = await contractInstance._uniswapWETH();
      assert.equal(result, compoundDAIAddress, 'wrong Uniswap SinceraWETH address');
    });
  });

  describe("configureAave", () => {
    it('success', async () => {
      const lendingPoolAddressesProvider = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
      await contractInstance.configureUniswap(lendingPoolAddressesProvider, { from: ownerAddress });
      const result = await contractInstance._aaveProvider();
      assert.equal(result, compoundDAIAddress, 'wrong AAVE Provider address');
    });
  });
  */

  describe("changeName", () => {
    it('success', async () => {
      const newName = "Novo Nome";
      await contractInstance.changeName(web3.utils.utf8ToHex(newName), { from: ownerAddress });
      const result = await contractInstance.name();
      const resultString = web3.utils.hexToUtf8(result);
      assert.equal(resultString, newName, 'wrong name');
    });
    it('event emmited', async () => {
      const newName = web3.utils.utf8ToHex("Novo Nome");
      const result = await contractInstance.changeName(newName, { from: ownerAddress });
      Assert.eventEmitted(
        result,
        'LogChangeName');
    });
  });

  describe("changeCut", () => {
    it('success', async () => {
      const newCut = 3;
      await contractInstance.changeCut(web3.utils.numberToHex(newCut), { from: ownerAddress });
      const result = await contractInstance.cut();
      const resultString = web3.utils.hexToNumber(result);
      assert.equal(resultString, newCut, 'wrong cut');
    });
    it('event emmited', async () => {
      const newCut = web3.utils.numberToHex(3);
      const result = await contractInstance.changeCut(newCut, { from: ownerAddress });
      Assert.eventEmitted(
        result,
        'LogChangeCut');
    });
  });

  /* PRIVATE
  describe("changeStudentGSNDeposit", () => {
    it('success', async () => {
      const newGSN = "1000000";
      await contractInstance.changeStudentGSNDeposit(web3.utils.utf8ToHex(newGSN), { from: ownerAddress });
      const result = await contractInstance.cut();
      const resultString = web3.utils.hexToUtf8(result);
      assert.equal(resultString, newGSN, 'wrong cut');
    });
    it('event emmited', async () => {
      const newGSN = web3.utils.utf8ToHex("1000000");
      const result = await contractInstance.changeStudentGSNDeposit(newGSN, { from: ownerAddress });
      Assert.eventEmitted(
        result,
        'LogchangeStudentGSNDeposit');
    });
  });
  */

  describe("New Student", () => {
    it('success', async () => {
      const sName = "Flavio Neto";
      await contractInstance.studentSelfRegister(web3.utils.utf8ToHex(sName), { from: student1Address });
      const result = await contractInstance.studentIsRegistered(student1Address, { from: ownerAddress });
      assert.equal(result, true, 'wrong');
    });
  });

});
