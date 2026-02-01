module.exports = {

    networks: {
        development: {
            host: "localhost",
            port: 8585,
            network_id: "*" // Match any network id
        }
    },
    mocha: {
    },

    compilers: {
        solc: {
            version: "0.8.21",

        }
    },
};