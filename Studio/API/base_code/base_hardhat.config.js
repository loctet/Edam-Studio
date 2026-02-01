require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: "0.8.28",
    networks: {
        hardhat: {
            accounts: {
                count: 1000,
                // accountsBalance: 10000000000000000000000, // default value is 10000ETH in wei
            },
        },
    },
    mocha: {
        timeout: 0,  // No timeout
      },
};
