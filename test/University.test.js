var web3 = require('web3');

require("@openzeppelin/test-helpers/configure")({
  provider: web3.currentProvider,
  singletons: {
    abstraction: "truffle"
  }
});

const Artifact = artifacts.require("../contracts/University");
const daiToken = artifacts.require("@openzeppelin/contracts/token/ERC20/IERC20.sol");
const Assert = require("truffle-assertions");

//const { time } = require("@openzeppelin/test-helpers");
//const differenceInDays = require("date-fns/differenceInDays");

contract("University", accounts => {

  //const name = process.env.UNIVERSITY_ADDRESS;
  //const cut = process.env.UNIVERSITY_CUT;
  //const studentGSNDeposit = process.env.UNIVERSITY_GSNDEPOSIT;
  //const daiAddress = process.env.UNIVERSITY_DAIADDRESS;
  //const compoundAddress = process.env.UNIVERSITY_COMPOUNDADDRESS;
  //const relayHubAddress = process.env.UNIVERSITY_RELAYHUBADDRESS;

  const tokenName = process.env.TOKEN_NAME;
  const tokenSymbol = process.env.TOKEN_SYMBOL;
  const tokenDecimals = process.env.TOKEN_DECIMALS;
  const tokenTotalSupply = process.env.TOKEN_SUPPLY;

  let contractInstance;
  let dai;

  const ownerAddress = accounts[0];
  const address1 = accounts[1];
  const address2 = accounts[2];

  before(async () => {
    web3.eth.defaultAccount = ownerAddress;
    dai = await daiToken.new(
      tokenName,
      tokenSymbol,
      tokenDecimals,
      tokenTotalSupply
    );
  });

  describe("constructor", () => {
    it('1 - Deploying contract properly...', async () => {
      Assert(contractInstance.address != '');
    });
  });
});