const Migrations = artifacts.require("University");

var Web3 = require("web3");

// Using Ropsten
const name = Web3.utils.asciiToHex("University");
const cut = 0.2 * 1e6;
const relayHubAddress = "0xD216153c06E857cD7f72665E0aF1d7D82172F494"; //same on every network
const classroomFactoryAddress = "0xe37980e7BF0E62281F13A3163Bf7FF580D20185E";
const studentFactoryAddress = "0x363966265fa8ab6fE016BF10a8c1e7FA364bD878";
const studentApplicationFactoryAddress =
    "0x0F1a2829339c0B5CcD9b6b353a8CD700de562850";
const daiAddress = "0xf80A32A835F79D7787E8a8ee5721D0fEaFd78108";
const compoundAddress = "0x6ce27497a64fffb5517aa4aee908b1e7eb63b9ff";
const ensContractAddress = "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e"; //same on every network
const ensTestRegistrarAddress = "0x09B5bd82f3351A4c8437FC6D7772A9E6cd5D25A1";
const ensPublicResolverAddress = "0x42D63ae25990889E35F215bC95884039Ba354115";
const ensReverseResolverAddres = "0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c";

module.exports = function(deployer) {
    deployer.deploy(
        Migrations,
        name,
        cut,
        daiAddress,
        compoundAddress,
        relayHubAddress,
        classroomFactoryAddress,
        studentFactoryAddress,
        studentApplicationFactoryAddress,
        ensContractAddress,
        ensTestRegistrarAddress,
        ensPublicResolverAddress,
        ensReverseResolverAddres
    );
};