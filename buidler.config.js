usePlugin("@nomiclabs/buidler-waffle");
module.exports = {
    defaultNetwork: "buidlerevm",
    solc: {
        version: '0.6.6',
        optimizer: { enabled: true, runs: 100 }
    },
    paths: {
        tests: './testsBuidler',
        artifacts: './build/contracts'
    },
    buidlerevm: {
        loggingEnabled: true,
    },
};