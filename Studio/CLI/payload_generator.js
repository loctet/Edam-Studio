const fs = require("fs");
const {
  edam_models,
} = require("./Models.js"); 

const {generateEDAM} = require("./helper.js");
const {getConfigSettings} = require("./DefaultApiConfigs.js");

// Function to generate the payload
// inputModels can be either:
// - Array of model names (strings) for predefined models
// - Array of EDAM model objects (already parsed from .edam files)
// - Mixed array of both
function generatePayload(inputModels, mode_gen, config, target_language) {
  const edams = inputModels.map((input) => {
    // If it's already an EDAM model object (parsed from .edam file)
    if (typeof input === 'object' && input.name && input.roles) {
      return input;
    }
    // Otherwise, treat it as a model name and look it up
    if (typeof input === 'string') {
      return edam_models[`edam_${input.toLowerCase()}`];
    }
    return null;
  }).filter((edam) => edam); // Filter out undefined/null models

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
// The input can be:
// - JSON string with array of model names and/or EDAM objects
// - Or the old format: model names as separate arguments
const args = process.argv.slice(2);
const mode_gen = args[args.length - 2]; // Extract mode_gen
const config = JSON.parse(args[args.length - 1]); // Extract config
const target_language = "solidity"; // Extract target_language

// Check if the first argument is a JSON array (new format with parsed EDAMs)
let inputModels;
try {
  // Try to parse as JSON first (for parsed EDAM objects)
  const jsonInput = JSON.parse(args[0]);
  if (Array.isArray(jsonInput)) {
    inputModels = jsonInput;
  } else {
    // Fall back to old format
    inputModels = args.slice(0, -2);
  }
} catch (e) {
  // Not JSON, use old format (model names as separate arguments)
  inputModels = args.slice(0, -2);
}

// Generate payload
const payload = generatePayload(inputModels, mode_gen, config, target_language);

// Write JSON payload to a file
fs.writeFileSync("output.json", JSON.stringify(payload, null, 2));

console.log("Payload written to output.json");