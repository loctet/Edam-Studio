const fs = require("fs");
const {
  edam_models,
} = require("./Models.js"); 

const {generateEDAM} = require("./helper.js");
const {getConfigSettings} = require("./DefaultApiConfigs.js");

// Function to generate the payload
function generatePayload(modelNames, mode_gen, config, target_language) {
  const edams = modelNames
    .map((name) => edam_models[`edam_${name.toLowerCase()}`])
    .filter((edam) => edam); // Filter out undefined models

  return {
    models: edams.map((edam) => ({
      edamCode: generateEDAM(edam),
      name: edam.name,
    })),
    server_settings: config,
    generation_mode: mode_gen,
    target_language: target_language
  };
}

// Read input from command-line arguments
const inputModels = process.argv.slice(2, -2); // Extract model names
const mode_gen = process.argv[process.argv.length - 2]; // Extract mode_gen
const config = JSON.parse(process.argv[process.argv.length - 1]); // Extract config
const target_language = "solidity"; // Extract target_language

// Generate payload
const payload = generatePayload(inputModels, mode_gen, config, target_language);

// Write JSON payload to a file
fs.writeFileSync("output.json", JSON.stringify(payload, null, 2));

console.log("Payload written to output.json");