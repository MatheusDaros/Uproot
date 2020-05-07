var web3 = require('web3');

require('dotenv').config();

const Contract = artifacts.require("University");
//const Dai = artifacts.require("ERC20");

contract("University test", accounts => {

  /*

  const tokenName = "dai";
  const tokenSymbol = "DAI";
  
  beforeEach(async () => {
    await Dai.deployed(tokenName, tokenSymbol);
    await Dai._mint(accounts[1], 10000);
  });

  */

  //TODO library and require
  function getAddress(file) {
    let input = require(file);
    let dKey = Object.keys(input.networks)[0];
    return input.networks[dKey].address;
  }

  //University Params
  const name = web3.utils.asciiToHex(process.env.UNIVERSITY_NAME);
  const cut = web3.utils.asciiToHex(process.env.UNIVERSITY_CUT);
  const studentGSNDeposit = web3.utils.asciiToHex(process.env.UNIVERSITY_GSNDEPOSIT);
  const relayHubAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"; //getAddress('../build/contracts/CERC20.json');
  const classroomFactoryAddress = getAddress('../build/contracts/ClassroomFactory.json');
  const studentFactoryAddress = getAddress('../build/contracts/StudentFactory.json');
  const studentApplicationFactoryAddress = getAddress('../build/contracts/StudentApplicationFactory.json');
  const daiAddress = getAddress('../build/contracts/ERC20.json');

  describe("constructor", () => {
    it('1 - Deploying contract properly...', async () => {
      await Contract.deployed(name, cut, studentGSNDeposit, relayHubAddress, classroomFactoryAddress, studentFactoryAddress, studentApplicationFactoryAddress, daiAddress);
      assert(Contract.address != '');
    });

    it('2 - Store Name...', async () => {
      await Contract.deployed(name, cut, studentGSNDeposit, relayHubAddress, classroomFactoryAddress, studentFactoryAddress, studentApplicationFactoryAddress, daiAddress);
      var UniversityName = await Contract.Name();
      assert(UniversityName === web3.utils.asciiToHex(process.env.UNIVERSITY_NAME));
    });

    it('3 - Store Admin Role...', async () => {
      await Contract.deployed(name, cut, studentGSNDeposit, relayHubAddress, classroomFactoryAddress, studentFactoryAddress, studentApplicationFactoryAddress, daiAddress);
      var AdminRole = await Contract.DEFAULT_ADMIN_ROLE();
      assert(AdminRole === accounts[0]);
    });

    it('4 - Store Admin Role...', async () => {
      await Contract.deployed(name, cut, studentGSNDeposit, relayHubAddress, classroomFactoryAddress, studentFactoryAddress, studentApplicationFactoryAddress, daiAddress);
      var AdminRole = await Contract.DEFAULT_ADMIN_ROLE();
      assert(AdminRole != accounts[1]);
    });

  });

  describe("configureCompound", () => {
    it('5 - Compund DAI Address Save properly...', async () => {
      await Contract.deployed(name, cut, studentGSNDeposit, relayHubAddress, classroomFactoryAddress, studentFactoryAddress, studentApplicationFactoryAddress, daiAddress);
      var compoundDAIAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
      var comptrollerAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
      var priceOracleAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
      await Contract.configureCompound(compoundDAIAddress, comptrollerAddress, priceOracleAddress)
      var AddressSave = Contract.cDAI()
      assert(compoundDAIAddress === AddressSave);
    });
    it('6 - Compund Controller Address Save properly...', async () => {
      await Contract.deployed(name, cut, studentGSNDeposit, relayHubAddress, classroomFactoryAddress, studentFactoryAddress, studentApplicationFactoryAddress, daiAddress);
      var compoundDAIAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
      var comptrollerAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
      var priceOracleAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
      await Contract.configureCompound(compoundDAIAddress, comptrollerAddress, priceOracleAddress)
      var AddressSave = Contract.comptroller()
      assert(comptrollerAddress === AddressSave);
    });
    it('6 - Compund Price Oracle Address Save properly...', async () => {
      await Contract.deployed(name, cut, studentGSNDeposit, relayHubAddress, classroomFactoryAddress, studentFactoryAddress, studentApplicationFactoryAddress, daiAddress);
      var compoundDAIAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
      var comptrollerAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
      var priceOracleAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
      await Contract.configureCompound(compoundDAIAddress, comptrollerAddress, priceOracleAddress)
      var AddressSave = Contract.comptroller()
      assert(priceOracleAddress === AddressSave);
    });

  });

});