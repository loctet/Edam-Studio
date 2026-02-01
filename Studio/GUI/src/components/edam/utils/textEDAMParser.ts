import type { EDAMModel, EDAMTransition, ExternalCall } from "@edams-models/edam/types";
import { parseExpression } from "./expressionHelper";

/**
 * Parse a text-based EDAM format into an EDAMModel
 * 
 * Format:
 * Line 1: EDAM name
 * Line 2: Roles (comma separated)
 * Line 3: Variables (var:type, comma separated)
 * Following lines: Transitions
 *   [from] {userVar:role:mode, }, guard, [external calls] callerVar.functionName(params){assignments} {user:role:mode} [to]
 */
export function parseTextEDAM(text: string): EDAMModel {
  const lines = text.split('\n').map(line => line.trim()).filter(line => line.length > 0);
  
  if (lines.length < 3) {
    throw new Error("EDAM text must have at least 3 lines: name, roles, and variables");
  }

  // Parse name (first line)
  const name = lines[0];

  // Parse roles (second line)
  const roles = lines[1].split(',').map(r => r.trim()).filter(r => r.length > 0);

  // Parse variables (third line)
  const variablesList: string[] = [];
  const variables: Record<string, string> = {};
  if (lines[2]) {
    const varParts = lines[2].split(',').map(v => v.trim()).filter(v => v.length > 0);
    varParts.forEach(varPart => {
      const [varName, varType] = varPart.split(':').map(s => s.trim());
      if (varName && varType) {
        variablesList.push(varName);
        variables[varName] = varType;
      }
    });
  }

  // Parse transitions (remaining lines)
  const transitions: EDAMTransition[] = [];
  const states = new Set<string>();
  const externalContracts = new Set<string>();
  
  for (let i = 3; i < lines.length; i++) {
    const line = lines[i];
    if (!line || line.trim().length === 0) continue;
    
    try {
      const transition = parseTransitionLine(line, roles, variables);
      transitions.push(transition);
      states.add(transition.from);
      states.add(transition.to);
      
      // Collect external contract names from external calls
      const externalCalls = transition.guard?.[1] || [];
      externalCalls.forEach((call: ExternalCall) => {
        if (call.modelName) {
          externalContracts.add(call.modelName);
        }
      });
    } catch (error) {
      console.error(`Error parsing transition at line ${i + 1}:`, error);
      throw new Error(`Error parsing transition at line ${i + 1}: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  // Add external contracts as variables with the same type as the contract name
  externalContracts.forEach(contractName => {
    if (!variables[contractName]) {
      variables[contractName] = contractName;
      variablesList.push(contractName);
    }
  });

  // Filter out "_" from states - "_" is always the initial state but not in the states list
  const statesArray = Array.from(states).filter(state => state !== "_");
  // "_" is always the initial state
  const initialState = "_";

  return {
    name,
    roles,
    states: statesArray,
    initialState,
    finalStates: [],
    transitions,
    variablesList,
    variables,
    participantsList: {}
  };
}

/**
 * Parse a single transition line
 * Format: [from] {userVar:role:mode, }, guard, [external calls] callerVar.functionName(params){assignments} {user:role:mode} [to]
 */
function parseTransitionLine(line: string, roles: string[], variables: Record<string, string>): EDAMTransition {
  // Extract from state: [state]
  const fromMatch = line.match(/^\[([^\]]+)\]/);
  if (!fromMatch) {
    throw new Error("Missing [from] state");
  }
  const from = fromMatch[1].trim();

  // Extract to state: [state] at the end
  const toMatch = line.match(/\[([^\]]+)\]\s*$/);
  if (!toMatch) {
    throw new Error("Missing [to] state");
  }
  const to = toMatch[1].trim();

  // Extract rho (before guard): {userVar:role:mode, }
  const rhoMatch = line.match(/^\[[^\]]+\]\s*\{([^}]*)\}/);
  const rho = rhoMatch ? parseRho(rhoMatch[1], roles) : [];

  // Extract rhoPrime (before [to]): {user:role:mode}
  const rhoPrimeMatch = line.match(/\{([^}]+)\}\s*\[[^\]]+\]\s*$/);
  const rhoPrime = rhoPrimeMatch ? parseRho(rhoPrimeMatch[1], roles) : [];

  // Extract guard (between rho and external calls)
  // Format: [from] {rho}, guard, [external calls] ...
  // Find the comma after rho block
  const rhoEnd = line.indexOf('}', line.indexOf('['));
  if (rhoEnd === -1) {
    throw new Error("Invalid format: missing rho block");
  }
  
  const commaAfterRho = line.indexOf(',', rhoEnd);
  if (commaAfterRho === -1) {
    throw new Error("Invalid format: missing comma after rho");
  }
  
  // Find the next comma (before external calls) or bracket [
  let guard = '';
  let externalCallsStart = -1;
  
  // Find the operation first to know where to stop looking for external calls
  // The operation comes after external calls, so we need to find it to know the bounds
  const operationMatchForBounds = line.match(/(\w+):(\w+)\s*\(/);
  const operationIndex = operationMatchForBounds ? operationMatchForBounds.index : -1;
  
  // Look for external calls bracket [ (should be after guard and before operation)
  // We need to find the bracket that's between the guard and the operation
  let externalCallsBracket = -1;
  if (operationIndex !== -1) {
    // Look for bracket between commaAfterRho and operation
    const searchStart = commaAfterRho;
    const searchEnd = operationIndex;
    let bracketPos = line.indexOf('[', searchStart);
    while (bracketPos !== -1 && bracketPos < searchEnd) {
      // Check if this bracket is for external calls (not a state bracket)
      // External calls bracket should contain function calls like model.function()
      const bracketContent = line.substring(bracketPos + 1);
      const closingBracket = bracketContent.indexOf(']');
      if (closingBracket !== -1) {
        const content = bracketContent.substring(0, closingBracket);
        // Check if it looks like external calls (contains .function() pattern)
        if (content.includes('.') && content.includes('(')) {
          externalCallsBracket = bracketPos;
          break;
        }
      }
      bracketPos = line.indexOf('[', bracketPos + 1);
    }
  } else {
    // No operation found, look for any bracket after commaAfterRho
    externalCallsBracket = line.indexOf('[', commaAfterRho);
  }
  
  // Look for the comma that separates guard from external calls
  // Format: guard, [external calls] or guard, [external calls] operation
  const commaBeforeExternalCalls = externalCallsBracket !== -1 
    ? line.lastIndexOf(',', externalCallsBracket)
    : -1;
  
  if (commaBeforeExternalCalls > commaAfterRho) {
    // Guard is between the two commas
    guard = line.substring(commaAfterRho + 1, commaBeforeExternalCalls).trim();
    // Find the actual bracket position after the comma (skip whitespace)
    const afterComma = line.substring(commaBeforeExternalCalls + 1).trimStart();
    const bracketPos = line.indexOf('[', commaBeforeExternalCalls + 1);
    externalCallsStart = bracketPos !== -1 ? bracketPos : commaBeforeExternalCalls + 1;
  } else if (externalCallsBracket !== -1 && externalCallsBracket > commaAfterRho) {
    // Guard is between comma and external calls bracket (no comma between them)
    guard = line.substring(commaAfterRho + 1, externalCallsBracket).trim();
    externalCallsStart = externalCallsBracket;
  } else {
    // No external calls bracket found, guard is until operation or next comma
    if (operationIndex !== -1) {
      // Check if there's a comma before the operation
      const commaBeforeOp = line.lastIndexOf(',', operationIndex);
      if (commaBeforeOp > commaAfterRho) {
        guard = line.substring(commaAfterRho + 1, commaBeforeOp).trim();
        // Find the actual bracket position after the comma (skip whitespace)
        const bracketPos = line.indexOf('[', commaBeforeOp + 1);
        externalCallsStart = bracketPos !== -1 && bracketPos < operationIndex ? bracketPos : commaBeforeOp + 1;
      } else {
        guard = line.substring(commaAfterRho + 1, operationIndex).trim();
      }
    } else {
      guard = line.substring(commaAfterRho + 1).trim();
    }
  }

  // Extract external calls: [model.function(expression), ...]
  const externalCalls: ExternalCall[] = [];
  let externalCallsEnd = -1;
  
  // Find the external calls bracket - it should be after the guard
  // If externalCallsStart was set, use it; otherwise try to find the bracket
  let actualExternalCallsStart = externalCallsStart;
  
  // Debug logging
  console.log('Parsing external calls:', {
    line,
    commaAfterRho,
    externalCallsStart,
    operationIndex,
    guard
  });
  
  if (actualExternalCallsStart === -1 || (actualExternalCallsStart < line.length && line[actualExternalCallsStart] !== '[')) {
    // Try to find the bracket manually - it should be between guard and operation
    if (operationIndex !== -1) {
      // Look for bracket between commaAfterRho and operation
      let bracketPos = line.indexOf('[', commaAfterRho);
      while (bracketPos !== -1 && bracketPos < operationIndex) {
        // Check if this bracket contains external calls (has .function() pattern)
        const bracketContent = line.substring(bracketPos + 1);
        const closingBracket = bracketContent.indexOf(']');
        if (closingBracket !== -1) {
          const content = bracketContent.substring(0, closingBracket);
          // Check if it looks like external calls (contains .function() pattern)
          if (content.includes('.') && content.includes('(')) {
            actualExternalCallsStart = bracketPos;
            console.log('Found external calls bracket at:', bracketPos, 'content:', content);
            break;
          }
        }
        bracketPos = line.indexOf('[', bracketPos + 1);
      }
    }
  }
  
  if (actualExternalCallsStart !== -1 && actualExternalCallsStart < line.length && line[actualExternalCallsStart] === '[') {
    const callsMatch = line.substring(actualExternalCallsStart).match(/^\[([^\]]*)\]/);
    if (callsMatch) {
      externalCallsEnd = actualExternalCallsStart + callsMatch[0].length;
      if (callsMatch[1].trim()) {
        const callsText = callsMatch[1].trim();
        console.log('Parsing external calls text:', callsText);
        // We'll parse external calls later after we have paramVar and ptpVar
        // For now, just store the text
        const parsedCalls = parseExternalCalls(callsText, variables, {}, '');
        console.log('Parsed external calls:', parsedCalls);
        externalCalls.push(...parsedCalls);
      }
    }
  } else {
    console.log('No external calls bracket found. actualExternalCallsStart:', actualExternalCallsStart, 'char at pos:', actualExternalCallsStart !== -1 && actualExternalCallsStart < line.length ? line[actualExternalCallsStart] : 'N/A');
  }

  // Extract operation: callerVar:functionName(params)
  // The operation comes AFTER the external calls bracket (if present)
  // Find the pattern: var:functionName(params) but only after external calls
  // Format changed: caller:operation(params) instead of caller.operation(params)
  let operationStartIndex = externalCallsEnd !== -1 ? externalCallsEnd : commaAfterRho;
  if (operationStartIndex === -1) {
    operationStartIndex = 0;
  }
  
  // Find operation pattern after external calls - using : instead of .
  const operationMatch = line.substring(operationStartIndex).match(/(\w+):(\w+)\s*\(([^)]*)\)/);
  let ptpVar = '';
  let operation = '';
  let paramVar: Record<string, string> = {};
  let ptpVarList: string[] = [];
  
  if (operationMatch) {
    ptpVar = operationMatch[1].trim();
    operation = operationMatch[2].trim();
    const paramsText = operationMatch[3].trim();
    if (paramsText) {
      paramVar = parseParams(paramsText);
      // Extract ptpVarList from parameters that are participant types
      // Look for parameters with type "pt" or participant-related types
      ptpVarList = Object.entries(paramVar)
        .filter(([name, type]) => {
          // Check if type indicates a participant (pt, participant, or if name suggests participant)
          const lowerType = type.toLowerCase();
          return lowerType === 'pt' || 
                 lowerType.includes('participant') || 
                 lowerType === 'address' || // addresses are often participants
                 name.toLowerCase().startsWith('pt') ||
                 name.toLowerCase().startsWith('p') && name.length <= 3; // short names like p1, p2
        })
        .map(([name]) => name);
    }
  }

  // Extract assignments: {var=expression, ...}
  const assignmentsMatch = line.match(/\{([^}]*)\}/g);
  let assignments: Record<string, string> = {};
  
  // Find the assignments block (usually the second or third {})
  if (assignmentsMatch && assignmentsMatch.length > 1) {
    // The assignments are typically in a block like {var=expr, var=expr}
    // It's usually the one that's not rho or rhoPrime
    for (const match of assignmentsMatch) {
      const content = match.slice(1, -1).trim();
      // Check if it looks like assignments (contains =)
      if (content.includes('=') && !content.includes(':')) {
        assignments = parseAssignments(content);
        break;
      }
    }
  }

  // Re-parse external calls now that we have paramVar and ptpVar
  if (externalCalls.length > 0 && actualExternalCallsStart !== -1 && line[actualExternalCallsStart] === '[') {
    const callsMatch = line.substring(actualExternalCallsStart).match(/^\[([^\]]*)\]/);
    if (callsMatch && callsMatch[1].trim()) {
      const callsText = callsMatch[1].trim();
      // Re-parse with full context
      externalCalls.length = 0; // Clear existing
      externalCalls.push(...parseExternalCalls(callsText, variables, paramVar, ptpVar));
    }
  }

  // Parse guard expression to OCaml format
  // Always include external calls in guard, even if guard is empty
  let parsedGuard: [string, ExternalCall[]] | undefined;
  if (guard && guard.length > 0) {
    try {
      const parsedGuardExpr = parseExpression(guard);
      parsedGuard = [parsedGuardExpr, externalCalls];
    } catch (error) {
      console.warn(`Could not parse guard expression: ${guard}`, error);
      parsedGuard = [guard, externalCalls];
    }
  } else if (externalCalls.length > 0) {
    // If guard is empty but we have external calls, still create guard with true
    parsedGuard = ['Val (BoolVal true)', externalCalls];
  }

  return {
    from,
    to,
    operation: operation || 'unknown',
    guard: parsedGuard,
    ptpVar,
    ptpVarList,
    rho,
    rhoPrime,
    paramVar,
    assignments
  };
}

/**
 * Parse rho/rhoPrime format: userVar:role:mode, userVar2:role2:mode2
 */
function parseRho(rhoText: string, roles: string[]): any[] {
  if (!rhoText || rhoText.trim().length === 0) {
    return [];
  }

  const entries = rhoText.split(',').map(e => e.trim()).filter(e => e.length > 0);
  const result: any[] = [];

  entries.forEach(entry => {
    const parts = entry.split(':').map(p => p.trim());
    if (parts.length >= 3) {
      const [user, role, mode] = parts;
      result.push({
        user,
        role,
        mode: mode === 'Top' ? 'Top' : mode === 'Bottom' ? 'Bottom' : 'Unknown'
      });
    }
  });

  return result;
}

/**
 * Parse external calls: model.function(expression), model2.function2(expr2)-, model3.f3(expr3)
 * The '-' suffix indicates the call is expected to fail (enabled: false)
 * 
 * @param callsText - The text containing external calls
 * @param variables - Map of variable names to their types from the EDAM
 * @param paramVar - Map of parameter names to their types from the operation
 * @param ptpVar - The caller variable name (always a participant)
 */
function parseExternalCalls(
  callsText: string, 
  variables: Record<string, string>, 
  paramVar: Record<string, string>,
  ptpVar: string
): ExternalCall[] {
  if (!callsText || callsText.trim().length === 0) {
    return [];
  }

  const calls: ExternalCall[] = [];
  
  // Match pattern: model.function(args) or model.function(args)-
  // We'll find all matches and then check for '-' suffix
  const callPattern = /(\w+)\.(\w+)\s*\(([^)]*)\)/g;
  let match;

  while ((match = callPattern.exec(callsText)) !== null) {
    const [, modelName, operation, argsText] = match;
    const matchEnd = callPattern.lastIndex;
    
    // Check if there's a '-' right after the closing parenthesis
    // Look at the text right after the match
    const textAfterMatch = callsText.substring(matchEnd).trim();
    const hasFailureMarker = textAfterMatch.startsWith('-') || 
                            textAfterMatch.startsWith('-,') ||
                            textAfterMatch.startsWith('- ,');
    const enabled = !hasFailureMarker;
    
    // Parse arguments - separate data arguments from participant arguments
    const dataArgs: any[] = [];
    const participantArgs: any[] = [];
    
    if (argsText && argsText.trim()) {
      // Split arguments by comma, but be careful with nested expressions
      // For now, simple split - this might need improvement for complex expressions
      const argParts = argsText.split(',').map(a => a.trim()).filter(a => a.length > 0);
      
      for (const arg of argParts) {
        // Check if this argument is a participant variable
        const isParticipant = isParticipantVariable(arg, variables, paramVar, ptpVar);
        
        if (isParticipant) {
          // It's a participant - add to participant args
          participantArgs.push(arg);
        } else {
          // It's a data argument (expression) - parse it
          try {
            const parsedExpr = parseExpression(arg);
            dataArgs.push(parsedExpr);
          } catch (error) {
            console.warn(`Could not parse argument expression: ${arg}`, error);
            dataArgs.push(arg);
          }
        }
      }
    }
    
    calls.push({
      type: "externalCall",
      modelName: modelName.trim(),
      operation: operation.trim(),
      args: [participantArgs, dataArgs], // [participant args, data args]
      enabled: enabled
    });
  }

  return calls;
}

/**
 * Check if a variable is a participant
 * @param varName - The variable name to check
 * @param variables - Map of variable names to types from EDAM
 * @param paramVar - Map of parameter names to types from operation
 * @param ptpVar - The caller variable name
 */
function isParticipantVariable(
  varName: string,
  variables: Record<string, string>,
  paramVar: Record<string, string>,
  ptpVar: string
): boolean {
  // Check if it's the caller
  if (varName === ptpVar) {
    return true;
  }
  
  // Check if it's in operation parameters with type "pt"
  if (paramVar[varName]) {
    const type = paramVar[varName].toLowerCase();
    return type === 'pt' || type.includes('participant');
  }
  
  // Check if it's in EDAM variables with type "pt"
  if (variables[varName]) {
    const type = variables[varName].toLowerCase();
    return type === 'pt' || type.includes('participant');
  }
  
  // If it's just a simple variable name (not an expression), it might be a participant
  // But we can't be sure, so return false for safety
  // Expressions like "counter+1" are definitely not participants
  if (varName.match(/^[a-zA-Z_][a-zA-Z0-9_]*$/)) {
    // It's a simple variable name, but we don't know its type
    // Default to false - user should specify type in params or variables
    return false;
  }
  
  return false;
}

/**
 * Parse parameters: var:type, var2:type2
 */
function parseParams(paramsText: string): Record<string, string> {
  const params: Record<string, string> = {};
  
  if (!paramsText || paramsText.trim().length === 0) {
    return params;
  }

  const paramParts = paramsText.split(',').map(p => p.trim()).filter(p => p.length > 0);
  paramParts.forEach(paramPart => {
    const [name, type] = paramPart.split(':').map(s => s.trim());
    if (name && type) {
      params[name] = type;
    }
  });

  return params;
}

/**
 * Parse assignments: var=expression, var2=expression2
 */
function parseAssignments(assignmentsText: string): Record<string, string> {
  const assignments: Record<string, string> = {};
  
  if (!assignmentsText || assignmentsText.trim().length === 0) {
    return assignments;
  }

  // Split by comma, but be careful with commas inside expressions
  // Simple approach: split by comma and then check if it's a valid assignment
  const parts = assignmentsText.split(',').map(a => a.trim()).filter(a => a.length > 0);
  
  // Try to combine parts that might have been split incorrectly
  const assignmentParts: string[] = [];
  let currentPart = '';
  
  for (let i = 0; i < parts.length; i++) {
    const part = parts[i];
    if (part.includes('=')) {
      // This looks like an assignment
      if (currentPart) {
        assignmentParts.push(currentPart);
        currentPart = '';
      }
      assignmentParts.push(part);
    } else {
      // Might be continuation of previous expression
      if (currentPart) {
        currentPart += ', ' + part;
      } else {
        currentPart = part;
      }
    }
  }
  
  if (currentPart) {
    assignmentParts.push(currentPart);
  }

  assignmentParts.forEach(assignmentPart => {
    const equalIndex = assignmentPart.indexOf('=');
    if (equalIndex === -1) return;
    
    const varName = assignmentPart.substring(0, equalIndex).trim();
    const expression = assignmentPart.substring(equalIndex + 1).trim();
    
    if (varName && expression) {
      try {
        // Parse the expression to OCaml format
        const parsedExpr = parseExpression(expression);
        assignments[varName] = parsedExpr;
      } catch (error) {
        console.warn(`Could not parse assignment expression: ${expression}`, error);
        assignments[varName] = expression;
      }
    }
  });

  return assignments;
}

/**
 * Convert an EDAMModel to text format
 * @param model The EDAM model to convert
 * @returns Text representation of the EDAM model
 */
export function modelToTextEDAM(model: EDAMModel): string {
  const lines: string[] = [];
  
  // Line 1: EDAM name
  lines.push(model.name);
  
  // Line 2: Roles (comma separated)
  lines.push(model.roles.join(','));
  
  // Line 3: Variables (var:type, comma separated)
  const variables = model.variablesList?.map(varName => {
    const type = model.variables?.[varName] || 'string';
    return `${varName}:${type}`;
  }) || [];
  lines.push(variables.length > 0 ? variables.join(', ') : '');
  
  // Lines 4+: Transitions
  model.transitions.forEach(transition => {
    const transitionLine = formatTransition(transition);
    lines.push(transitionLine);
  });
  
  return lines.join('\n');
}

/**
 * Format a single transition to text format
 * Format: [from] {rho}, guard, [external_calls] caller:operation(params){assignments} {rhoPrime} [to]
 */
function formatTransition(transition: EDAMTransition): string {
  const parts: string[] = [];
  
  // [from_state]
  parts.push(`[${transition.from}]`);
  
  // {rho}
  const rhoStr = formatRho(transition.rho || []);
  parts.push(`{${rhoStr}}`);
  
  // guard
  const guard = transition.guard?.[0] || '';
  parts.push(guard);
  
  // [external_calls]
  const externalCalls = transition.guard?.[1] || [];
  const externalCallsStr = formatExternalCalls(externalCalls);
  if (externalCallsStr) {
    parts.push(`[${externalCallsStr}]`);
  } else {
    parts.push('[]');
  }
  
  // caller:operation(params)
  const caller = transition.ptpVar || '';
  const operation = transition.operation || '';
  const params = formatParams(transition.paramVar || {});
  parts.push(`${caller}:${operation}(${params})`);
  
  // {assignments}
  const assignmentsStr = formatAssignments(transition.assignments || {});
  parts.push(`{${assignmentsStr}}`);
  
  // {rhoPrime}
  const rhoPrimeStr = formatRho(transition.rhoPrime || []);
  parts.push(`{${rhoPrimeStr}}`);
  
  // [to_state]
  parts.push(`[${transition.to}]`);
  
  return parts.join(' ');
}

/**
 * Format rho/rhoPrime array to string
 */
function formatRho(rho: any[]): string {
  if (!rho || rho.length === 0) {
    return '';
  }
  
  return rho.map(item => {
    // Handle different rho formats
    if (typeof item === 'object') {
      const user = item.user || item[Object.keys(item)[0]];
      const role = item.role || item[Object.keys(item)[1]];
      const mode = item.mode || item[Object.keys(item)[2]];
      return `${user}:${role}:${mode}`;
    }
    return String(item);
  }).join(', ');
}

/**
 * Format external calls to string
 */
function formatExternalCalls(externalCalls: ExternalCall[]): string {
  if (!externalCalls || externalCalls.length === 0) {
    return '';
  }
  
  return externalCalls.map(call => {
    const modelName = call.modelName || '';
    const operation = call.operation || '';
    const args = call.args || [[], []];
    const participantArgs = args[0] || [];
    const dataArgs = args[1] || [];
    const allArgs = [...participantArgs, ...dataArgs];
    const argsStr = allArgs.join(', ');
    const enabled = call.enabled !== false;
    return `${modelName}.${operation}(${argsStr})${enabled ? '' : '-'}`;
  }).join(', ');
}

/**
 * Format parameters to string
 */
function formatParams(paramVar: Record<string, string>): string {
  if (!paramVar || Object.keys(paramVar).length === 0) {
    return '';
  }
  
  return Object.entries(paramVar)
    .map(([name, type]) => `${name}:${type}`)
    .join(', ');
}

/**
 * Format assignments to string
 */
function formatAssignments(assignments: Record<string, string>): string {
  if (!assignments || Object.keys(assignments).length === 0) {
    return '';
  }
  
  return Object.entries(assignments)
    .map(([varName, expression]) => `${varName}=${expression}`)
    .join(', ');
}

