const path = require("path");

// Register ts-node so we can import the shared TypeScript generator
require("ts-node").register({
  transpileOnly: true,
  compilerOptions: {
    module: "commonjs",
    moduleResolution: "node",
    esModuleInterop: true,
    allowSyntheticDefaultImports: true,
    jsx: "react-jsx",
    resolveJsonModule: true,
    target: "es2019",
  },
});

const generatorPath = path.resolve(
  __dirname,
  "../../shared/edam/modelGenerator.ts"
);

const { generateEDAM } = require(generatorPath);

module.exports = { generateEDAM };