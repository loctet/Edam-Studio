const config = require('../config.json');
// Load main config
const mainConfig = {
    absoluteArtifactsDir: config.sumo.absolute_sumo_dir + '/.sumo/artifacts',
    absoluteSumoDir: config.sumo.absolute_sumo_dir + '/.sumo',
    sumoDir: '.sumo',
    resultsDir: '.sumo/results',
    artifactsDir: '.sumo/artifacts',
    baselineDir: '.sumo/baseline',
    targetDir: '',
    contractsDir: '',
    testDir: '',
    buildDir: '',
    skipContracts: [],
    skipTests: [],
    testUtils: [],
    excludedFunctions: ["roleSatisf", "_roles"],
    bail: true,
    customTestScript: true,
    ganache: false,
    optimized: true,
    regression: false,
    tce: false,
    testingTimeOutInSec: 300000,
    contractsGlob: '/**/*.sol',
    packageManagerGlob: ['/package-lock.json'],
    testConfigGlob: ['/hardhat.config.js'],
    testsGlob: '/**/*.{js,sol,ts}',
    ignore: ["artifacts"],
};

// Load temporary config
const tempConfig = require('./config_temp');

// Merge configs, prioritizing tempConfig for overwrites
const mergedConfig = {
    ...mainConfig,
    ...tempConfig,
};

module.exports = mergedConfig;
