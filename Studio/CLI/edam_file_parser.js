const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

// __dirname is Studio/CLI, so we go up one level to get Studio directory
const studioDir = path.resolve(__dirname, "..");
const parserPath = path.resolve(
  studioDir,
  "GUI/src/components/edam/utils/textEDAMParser.ts"
);

/**
 * Parse a .edam file and return the EDAM model as JSON
 * Uses a child process with tsx or ts-node to handle ES modules
 * @param {string} filePath - Path to the .edam file
 * @returns {Object} - Parsed EDAM model
 */
function parseEdamFile(filePath) {
  // Verify the parser file exists
  if (!fs.existsSync(parserPath)) {
    throw new Error(`Parser file not found at: ${parserPath}`);
  }
  
  // Create a temporary script that imports and uses the parser
  // Use .ts extension so ts-node can handle it
  const tempScript = path.join(__dirname, ".temp_parse_edam.ts");
  const scriptContent = `import { parseTextEDAM } from "${parserPath.replace(/\\/g, "/")}";
import { readFileSync } from "fs";

const filePath = process.argv[2];
const content = readFileSync(filePath, "utf-8");
const model = parseTextEDAM(content);
console.log(JSON.stringify(model, null, 2));
`;
  
  try {
    fs.writeFileSync(tempScript, scriptContent);
    
    // Use tsx (should be installed as dependency)
    // Try direct tsx first, then npx tsx, then node_modules/.bin/tsx
    let command;
    const tsxPaths = [
      "tsx",
      "npx tsx",
      path.join(studioDir, "node_modules", ".bin", "tsx")
    ];
    
    let tsxFound = false;
    for (const tsxPath of tsxPaths) {
      try {
        execSync(`${tsxPath} --version > /dev/null 2>&1`, { 
          cwd: studioDir,
          stdio: "ignore"
        });
        command = `${tsxPath} "${tempScript}" "${filePath}"`;
        tsxFound = true;
        break;
      } catch (e) {
        // Try next path
      }
    }
    
    if (!tsxFound) {
      throw new Error(
        "tsx is required to parse .edam files. Please install it:\n" +
        "  npm install tsx\n" +
        "Or run: cd Studio && npm install"
      );
    }
    
    const stdout = execSync(command, {
      cwd: studioDir,
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
      env: { ...process.env, NODE_OPTIONS: "" }
    });
    
    const model = JSON.parse(stdout);
    return model;
  } catch (error) {
    const errorMsg = error.stderr?.toString() || error.stdout?.toString() || error.message;
    throw new Error(`Parser failed: ${errorMsg}`);
  } finally {
    // Clean up temp files
    const tempFiles = [
      path.join(__dirname, ".temp_parse_edam.ts"),
      path.join(__dirname, ".temp_tsnode_wrapper.js")
    ];
    tempFiles.forEach(file => {
      if (fs.existsSync(file)) {
        try {
          fs.unlinkSync(file);
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    });
  }
}

// If called directly from command line
if (require.main === module) {
  const filePath = process.argv[2];
  
  if (!filePath) {
    console.error("Usage: node edam_file_parser.js <path_to_edam_file>");
    process.exit(1);
  }
  
  if (!fs.existsSync(filePath)) {
    console.error(`Error: File not found: ${filePath}`);
    process.exit(1);
  }
  
  try {
    const edamModel = parseEdamFile(filePath);
    console.log(JSON.stringify(edamModel, null, 2));
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  }
}

module.exports = { parseEdamFile };
