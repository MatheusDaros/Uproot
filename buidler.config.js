usePlugin("@nomiclabs/buidler-waffle");

// This is a sample Buidler task. To learn how to create your own go to
// https://buidler.dev/guides/create-task.html
task("accounts", "Prints the list of accounts", async() => {
    const accounts = await ethers.getSigners();

    for (const account of accounts) {
        console.log(await account.getAddress());
    }
});

module.exports = {
    solc: {
        version: '0.6.6'
    },
    paths: {
        tests: './testsBuidler'
    },
    optimizer: { enabled: true, runs: 2 }
};