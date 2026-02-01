const path = require("path");

// Register ts-node so we can load the TypeScript source of the edam models
require("ts-node").register({
  transpileOnly: true,
  compilerOptions: {
    module: "commonjs",
    moduleResolution: "node",
    esModuleInterop: true,
    allowSyntheticDefaultImports: true,
    jsx: "react-jsx",
    resolveJsonModule: true,
    target: "es2019"
  }
});

const modelsPath = path.resolve(__dirname, "../edams-models/edam/index.ts");

const { edam_models } = require(modelsPath);

module.exports = { edam_models };

/**
python3 ./cli.py  erc20token1 erc20token2 amm --mode 2 --number_symbolic_traces 2000
python3 ./cli.py  model1 model2 model3 --mode 2 --number_symbolic_traces 1

python3 ./cli.py  composed --mode 2 --number_symbolic_traces 1

python3 ./cli.py  assettransfer basicprovenance defectivecounter digitallocker frequentflyer helloblockchain refrigeratedtransport simplemarketplace thermostatoperation walletcontract erc20token1  --mode 4 --number_symbolic_traces 2000

python3 ./cli.py  erc20token1 simplemarketplace2 --mode 2 --number_symbolic_traces 10000

python3 ./cli.py  basicprovenance defectivecounter digitallocker frequentflyer helloblockchain --mode 4 --number_symbolic_traces 2000
python3 ./cli.py  refrigeratedtransport simplemarketplace thermostatoperation walletcontract erc20token1  --mode 4 --number_symbolic_traces 2000
python3 ./cli.py  c20 marketplace  --mode 3 --number_symbolic_traces 1000 --number_transition_per_trace 40

python3 ./cli.py  erc20token1 erc20token2 amm --mode 3 --number_symbolic_traces 500 --number_transition_per_trace 100

*/
