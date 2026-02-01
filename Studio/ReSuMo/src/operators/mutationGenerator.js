const fs = require('fs')
const parser = require("@solidity-parser/parser")
const configFileName = '../operators.config.json'
const configFile = require(configFileName)
const config = require('../config')

const Reporter = require('../reporter')
const reporter = new Reporter()

//Init operator version
var AOROperator
var BOROperator
var EROperator
var FVROperator
var GVROperator
var RVSOperator
var SFROperator
var VUROperator
var VVROperator

if (config.optimized) {
  AOROperator = require('./assignment-replacement')
  BOROperator = require('./binary-replacement')
  EROperator = require('./enum-replacement')
  FVROperator = require('./function-visibility-replacement')
  GVROperator = require('./global-variable-replacement')
  RVSOperator = require('./return-values-swap')
  SFROperator = require('./safemath-function-replacement')
  VUROperator = require('./variable-unit-replacement')
  VVROperator = require('./variable-visibility-replacement')

} else {
  AOROperator = require('./non-optimized/assignment-replacement')
  BOROperator = require('./non-optimized/binary-replacement')
  EROperator = require('./non-optimized/enum-replacement')
  FVROperator = require('./non-optimized/function-visibility-replacement')
  GVROperator = require('./non-optimized/global-variable-replacement')
  RVSOperator = require('./non-optimized/return-values-swap')
  SFROperator = require('./non-optimized/safemath-function-replacement')
  VUROperator = require('./non-optimized/variable-unit-replacement')
  VVROperator = require('./non-optimized/variable-visibility-replacement')

}

const ACMOperator = require('./argument-change-overloaded-call')
const AVROperator = require('./address-value-replacement')
const BCRDOperator = require('./break-continue-replacement')
const BLROperator = require('./boolean-literal-replacement')
const CBDOperator = require('./catch-block-deletion')
const CCDOperator = require('./constructor-deletion')
const CSCOperator = require('./conditional-statement-change')
const DLROperator = require('./data-location-replacement')
const DODOperator = require('./delete-operator-deletion')
const ECSOperator = require('./explicit-conversion-smaller')
const EEDOperator = require('./event-emission-deletion')
const EHCOperator = require('./exception-handling-change')
const ETROperator = require('./ether-transfer-function-replacement')
const ICMOperator = require('./increments-mirror')
const ILROperator = require('./integer-literal-replacement')
const LSCOperator = require('./loop-statement-change')
const HLROperator = require('./hex-literal-replacement')
const MCROperator = require('./math-crypto-function-replacement')
const MOCOperator = require('./modifier-order-change')
const MODOperator = require('./modifier-deletion')
const MOIOperator = require('./modifier-insertion')
const MOROperator = require('./modifier-replacement')
const OLFDOperator = require('./overloaded-function-deletion')
const OMDOperator = require('./overridden-modifier-deletion')
const ORFDOperator = require('./overridden-function-deletion')
const PKDOperator = require('./payable-deletion')
const RSDOperator = require('./return-statement-deletion')
const SCECOperator = require('./switch-call-expression-casting')
const SFDOperator = require('./selfdestruct-deletion')
const SFIOperator = require('./selfdestruct-insertion')
const SKDOperator = require('./super-keyword-deletion')
const SKIOperator = require('./super-keyword-insertion')
const SLROperator = require('./string-literal-replacement')
const TOROperator = require('./transaction-origin-replacement')
const UORDOperator = require('./unary-replacement')

function CompositeOperator(operators) {
  this.operators = operators
}

/**
 * Normalizes the excluded functions config to a consistent format.
 * Supports multiple formats:
 * - String: "functionName" or "functionName:lineNumber"
 * - Object: {name: "functionName", line: lineNumber} or {name: "functionName"}
 * @returns Array of objects with {name, line} format (line is optional)
 */
function normalizeExcludedFunctions() {
  if (!config.excludedFunctions || config.excludedFunctions.length === 0) {
    return [];
  }

  const normalized = [];
  for (const item of config.excludedFunctions) {
    if (typeof item === 'string') {
      // Check if it's in format "name:line"
      const parts = item.split(':');
      if (parts.length === 2 && parts[1] !== '') {
        const line = parseInt(parts[1], 10);
        if (!isNaN(line)) {
          normalized.push({ name: parts[0], line: line });
        } else {
          // Invalid line number, treat as name only
          normalized.push({ name: item });
        }
      } else {
        // Just function name, no line specified
        normalized.push({ name: item });
      }
    } else if (typeof item === 'object' && item !== null) {
      // Object format: {name: "...", line: ...}
      const normalizedItem = { name: item.name };
      if (item.line !== undefined && item.line !== null) {
        normalizedItem.line = parseInt(item.line, 10);
      }
      normalized.push(normalizedItem);
    }
  }
  return normalized;
}

/**
 * Checks if a function matches an exclusion entry.
 * @param {*} functionName the function name
 * @param {*} functionLine the function start line
 * @param {*} exclusionEntry normalized exclusion entry {name, line?}
 * @returns true if the function should be excluded
 */
function matchesExclusion(functionName, functionLine, exclusionEntry) {
  if (!functionName || functionName !== exclusionEntry.name) {
    return false;
  }

  // If line is specified in exclusion, must match exactly
  if (exclusionEntry.line !== undefined) {
    return functionLine === exclusionEntry.line;
  }

  // If no line specified, match all functions with this name
  return true;
}

/**
 * Gets the ranges of functions that are excluded from mutation.
 * Stores both the entire function range and the body range to exclude all mutations.
 * Supports excluding specific functions by name and line number to handle overloading.
 * @param {*} source the source code to parse
 * @returns Array of objects with function range information for excluded functions
 */
function getExcludedFunctionRanges(source) {
  const excludedRanges = [];
  const normalizedExclusions = normalizeExcludedFunctions();
  
  if (normalizedExclusions.length === 0) {
    return excludedRanges;
  }

  try {
    const ast = parser.parse(source, { range: true, loc: true });
    const visit = parser.visit.bind(parser, ast);

    visit({
      FunctionDefinition: (node) => {
        // Get function name (constructors don't have a name)
        const functionName = node.isConstructor ? null : (node.name || null);
        const functionStartLine = node.loc ? node.loc.start.line : null;
        
        if (!functionName || !functionStartLine) {
          return;
        }

        // Check if this function matches any exclusion entry
        for (const exclusion of normalizedExclusions) {
          if (matchesExclusion(functionName, functionStartLine, exclusion)) {
            // Store the entire function range (signature + body) and body range
            // This allows us to exclude both signature and body mutations
            if (node.range && node.body && node.body.range) {
              excludedRanges.push({
                functionStart: node.range[0],
                functionEnd: node.range[1] + 1,  // Entire function definition
                bodyStart: node.body.range[0],
                bodyEnd: node.body.range[1] + 1,  // Function body only
                functionName: functionName,
                functionLine: functionStartLine
              });
              break; // Found a match, no need to check other exclusions
            }
          }
        }
      }
    });
  } catch (error) {
    // If parsing fails, just return empty array (no exclusions)
    console.warn("Warning: Failed to parse source for function exclusion check:", error.message);
  }

  return excludedRanges;
}

/**
 * Checks if a mutation position falls within any excluded function (entire definition including signature and body).
 * @param {*} mutationStart the start position of the mutation
 * @param {*} mutationEnd the end position of the mutation
 * @param {*} excludedRanges array of excluded function ranges
 * @returns true if the mutation should be excluded
 */
function isMutationInExcludedFunction(mutationStart, mutationEnd, excludedRanges) {
  // Check if the mutation overlaps with any excluded function
  for (const range of excludedRanges) {
    // Exclude mutations that start within the function body
    // This excludes all mutations within the body, as requested by the user
    if (mutationStart >= range.functionStart && mutationStart < range.functionEnd) {
        return true;
    }
  }
  return false;
}

/**
 * Generates the mutations and saves them to report.
 * @param {*} file the path of the smart contract to be mutated
 * @param {*} source the content of the smart contract to be mutated
 * @param {*} visit the visitor
 * @param {*} overwrite  overwrite the generated mutation reports
 * @returns 
 */
CompositeOperator.prototype.getMutations = function (file, source, visit, overwrite) {
  let mutations = [];
  var fileString = "\n Mutants generated for file: " + file + ": \n";
  var mutantString = "";

  // Get excluded function ranges for this file
  const excludedRanges = getExcludedFunctionRanges(source);

  for (const operator of this.operators) {

    var enabled = Object.entries(configFile)
      .find(pair => pair[0] === operator.ID && pair[1] === true);

    if (enabled) {
      var opMutations = operator.getMutations(file, source, visit);
      
      // Filter out mutations that fall within excluded function bodies
      opMutations = opMutations.filter(mutation => {
        const isExcluded = isMutationInExcludedFunction(mutation.start, mutation.end, excludedRanges);
        return !isExcluded;
      });
      
      if (overwrite) {
        opMutations.forEach(m => {
          mutantString = mutantString + "- Mutant " + m.hash() + " was generated by " + operator.ID + " (" + operator.name + "). \n";
        });
      }
      mutations = mutations.concat(opMutations);
    }
  }

  if (overwrite && mutantString != "") {
    reporter.saveGeneratedMutants(fileString, mutantString);
  }
  return mutations;
}

//Retrieve list of enabled mutation operators
CompositeOperator.prototype.getEnabledOperators = function () {
  var enabled = Object.entries(configFile)
    .filter(pair => pair[1] === true);

  var printString = "Enabled mutations operators:";
  for (const pair of enabled) {
    printString = printString + '\n  - ' + pair[0];
  }
  if (printString === "Enabled mutations operators:")
    printString = printString + "\nNone"
  return printString
}

//Enables a mutation operator
CompositeOperator.prototype.enable = function (ID) {
  var exists = Object.entries(configFile)
    .find(pair => pair[0] === ID);

  if (exists) {
    configFile[ID] = true;
    fs.writeFileSync('./src/operators.config.json', JSON.stringify(configFile, null, 2), function writeJSON(err) {
      if (err) return console.log(err);
    });
    return true;
  }
  return false;
}

//Enables all mutation operators
CompositeOperator.prototype.enableAll = function () {
  Object.entries(configFile).forEach(pair => {
    configFile[pair[0]] = true;
  });
  fs.writeFileSync('./src/operators.config.json', JSON.stringify(configFile, null, 2), function writeJSON(err) {
    if (err) return false;
  });
  return true
}

//Disables a mutation operator
CompositeOperator.prototype.disable = function (ID) {
  var exists = Object.entries(configFile)
    .find(pair => pair[0] === ID);

  if (exists) {
    configFile[ID] = false;
    fs.writeFileSync('./src/operators.config.json', JSON.stringify(configFile, null, 2), function writeJSON(err) {
      if (err) return console.log(err);
    });
    return true;
  }
  return false;
}

//Disables all mutation operators
CompositeOperator.prototype.disableAll = function () {
  Object.entries(configFile).forEach(pair => {
    configFile[pair[0]] = false;
  });
  fs.writeFileSync('./src/operators.config.json', JSON.stringify(configFile, null, 2), function writeJSON(err) {
    if (err) return false;
  });
  return true
}

module.exports = {
  ACMOperator: ACMOperator,
  AOROperator: AOROperator,
  AVROperator: AVROperator,
  BCRDOperator: BCRDOperator,
  BLROperator: BLROperator,
  BOROperator: BOROperator,
  CBDOperator: CBDOperator,
  CCDOperator: CCDOperator,
  CSCOperator: CSCOperator,
  DLROperator: DLROperator,
  DODOperator: DODOperator,
  ECSOperator: ECSOperator,
  EEDOperator: EEDOperator,
  EHCOperator: EHCOperator,
  EROperator: EROperator,
  ETROperator: ETROperator,
  FVROperator: FVROperator,
  GVROperator: GVROperator,
  HLROperator: HLROperator,
  ICMOperator: ICMOperator,
  ILROperator: ILROperator,
  LSCOperator: LSCOperator,
  MCROperator: MCROperator,
  MOCOperator: MOCOperator,
  MODOperator: MODOperator,
  MOIOperator: MOIOperator,
  MOROperator: MOROperator,
  OLFDOperator: OLFDOperator,
  OMDOperator: OMDOperator,
  ORFDOperator: ORFDOperator,
  PKDOperator: PKDOperator,
  RSDOperator: RSDOperator,
  RVSOperator: RVSOperator,
  SCECOperator: SCECOperator,
  SFDOperator: SFDOperator,
  SFIOperator: SFIOperator,
  SFROperator: SFROperator,
  SKDOperator: SKDOperator,
  SKIOperator: SKIOperator,
  SLROperator: SLROperator,
  TOROperator: TOROperator,
  UORDOperator: UORDOperator,
  VUROperator: VUROperator,
  VVROperator: VVROperator,
  CompositeOperator: CompositeOperator,
}
