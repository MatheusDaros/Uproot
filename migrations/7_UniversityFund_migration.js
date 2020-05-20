const Migrations = artifacts.require("UniversityFund");

require("dotenv").config();

var Web3 = require("web3");

const universityAddress = "0xa03E45a84E253aE34C1298615cC3d140Bc69ECc9";
const daiAddress = "0xf80A32A835F79D7787E8a8ee5721D0fEaFd78108";
const compoundDAIAddress = "0x6ce27497a64fffb5517aa4aee908b1e7eb63b9ff";
const comptrollerAddress = "0xe03718b458a2E912141CF3fC8daB648362ee7463";
const priceOracleAddress = "0x9B8FBeF10F8c2E5c88a522DB2Ba6A1929D568699";
const uniswapWETH = "0xc778417e063141139fce010982780140aa0cd5ab";
const uniswapDAI = "0xf80A32A835F79D7787E8a8ee5721D0fEaFd78108";
const uniswapRouter = "0xf164fC0Ec4E93095b804a4795bBe1e041497b92a";
const lendingPoolAddressesProvider =
    "0x1c8756FD2B28e9426CDBDcC7E3c4d64fa9A54728";

module.exports = function(deployer) {
    deployer.deploy(
        Migrations,
        universityAddress,
        daiAddress,
        compoundDAIAddress,
        comptrollerAddress,
        priceOracleAddress,
        uniswapWETH,
        uniswapDAI,
        uniswapRouter,
        lendingPoolAddressesProvider
    );
};