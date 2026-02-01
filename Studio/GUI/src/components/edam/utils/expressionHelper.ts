// Function to parse a single value
function parseValue(value: string): string {
  if (!isNaN(Number(value))) {
    return `Val (IntVal ${value})`;
  } else if (value.toLowerCase() === "true" || value.toLowerCase() === "false") {
    return `Val (BoolVal ${value.toLowerCase()})`;
  } else {
    return `Val (StrVal "${value}")`;
  }
}

// Helper function to split an expression by the first occurrence of an operator
function splitExpression(expr: string, operator: string, caseInsensitive = false): [string, string] {
  let index;
  if (caseInsensitive) {
    const regex = new RegExp(`\\b${operator}\\b`, "i");
    index = expr.search(regex);
  } else {
    index = expr.indexOf(operator);
  }
  return [expr.slice(0, index), expr.slice(index + operator.length)];
}

// Function to parse an expression
export function parseExpression(expr: string, isOuter = true): string {
  expr = expr.trim();
  
  if (expr === "Val (BoolVal true)" || expr === "Val (BoolVal false)") {
    return expr;
  }

  if (expr === "true" || expr === "True") {
    return "Val (BoolVal true)";
  }

  if (expr === "false" || expr === "False") {
    return "Val (BoolVal false)";
  }

  if (expr.startsWith("getId(")) {
    const match = expr.match(/getId\((\w+)\)/);
    if (!match) throw new Error("Invalid getId expression");
    return `PtID (Ptp "${match[1]}")`;
  }

  // Handle arithmetic operations
  if (expr.includes("+") && !expr.startsWith("func(")) {
    const parts = splitExpression(expr, "+");
    return `Plus (${parseExpression(parts[0].trim())}, ${parseExpression(parts[1].trim())})`;
  }

  if (expr.includes("-")) {
    const parts = splitExpression(expr, "-");
    return `Minus (${parseExpression(parts[0].trim())}, ${parseExpression(parts[1].trim())})`;
  }

  if (expr.includes("*")) {
    const parts = splitExpression(expr, "*");
    return `Times (${parseExpression(parts[0].trim())}, ${parseExpression(parts[1].trim())})`;
  }

  if (expr.includes("/")) {
    const parts = splitExpression(expr, "/");
    return `Divide (${parseExpression(parts[0].trim())}, ${parseExpression(parts[1].trim())})`;
  }

  // Handle collections and functions
  if (expr.startsWith("sum(")) {
    const match = expr.match(/sum\((.+?)\)/);
    if (!match) throw new Error("Invalid sum expression");
    return `FuncCall ("sum", [${parseExpression(match[1].trim())}])`;
  }

  if (expr.startsWith("map ")) {
    const match = expr.match(/map\s+(\w+)\[(.+?)\]/);
    if (match) {
      const [_, varName, index] = match;
      const indexExp = parseExpression(index.trim(), false);
      return `MapIndex (Dvar (Var "${varName}"), ${indexExp}, Val (IntVal 0))`;
    }
  }

  if (expr.startsWith("list ")) {
    const match = expr.match(/list\s+(\w+)\[(.+?)\]/);
    if (match) {
      const [_, varName, index] = match;
      const indexExp = parseExpression(index.trim(), false);
      return `ListIndex (Dvar (Var "${varName}"), ${indexExp}, Val (IntVal 0))`;
    }
  }

  // Handle logical operations
  if (/\band\b/i.test(expr)) {
    const parts = splitExpression(expr, "and", true);
    return `And (${parseExpression(parts[0].trim())}, ${parseExpression(parts[1].trim())})`;
  }

  if (/\bor\b/i.test(expr)) {
    const parts = splitExpression(expr, "or", true);
    return `Or (${parseExpression(parts[0].trim())}, ${parseExpression(parts[1].trim())})`;
  }

  if (/\bnot\b/i.test(expr)) {
    const part = expr.slice(4).trim();
    return `Not (${parseExpression(part)})`;
  }

  // Handle comparisons
  if (expr.includes("==")) {
    const parts = splitExpression(expr, "==");
    return `Equal (${parseExpression(parts[0].trim())}, ${parseExpression(parts[1].trim())})`;
  }

  if (expr.includes(">=")) {
    const parts = splitExpression(expr, ">=");
    return `GreaterThanEqual (${parseExpression(parts[0].trim())}, ${parseExpression(parts[1].trim())})`;
  }

  if (expr.includes("<=")) {
    const parts = splitExpression(expr, "<=");
    return `LessThanEqual (${parseExpression(parts[0].trim())}, ${parseExpression(parts[1].trim())})`;
  }

  if (expr.includes(">")) {
    const parts = splitExpression(expr, ">");
    return `GreaterThan (${parseExpression(parts[0].trim())}, ${parseExpression(parts[1].trim())})`;
  }

  if (expr.includes("<")) {
    const parts = splitExpression(expr, "<");
    return `LessThan (${parseExpression(parts[0].trim())}, ${parseExpression(parts[1].trim())})`;
  }

  // Handle function calls
  if (expr.includes("(")) {
    const [func, params] = expr.split("(", 2);
    const parsedParams = params.slice(0, -1).split(",").map(param => parseExpression(param.trim()));
    return `FuncCall ("${func.trim()}", [${parsedParams.join(", ")}])`;
  }

  // Handle literals and variables
  if (!isNaN(Number(expr))) {
    return `Val (IntVal ${expr})`;
  }

  if (expr.toLowerCase() === "true" || expr.toLowerCase() === "false") {
    return `Val (BoolVal ${expr.toLowerCase()})`;
  }

  return `Dvar (Var "${expr}")`;
}

// Function to parse assignments
export function parseAssignments(assignments: string): Array<[string, string]> {
  return assignments.split(",")
    .map(assignment => assignment.trim())
    .filter(Boolean)
    .map(assignment => {
      const [lhs, rhs] = assignment.split(":=").map(part => part.trim());

      if (/map\s+\w+\[.+?\]/.test(lhs)) {
        const match = lhs.match(/map\s+(\w+)\[(.+?)\]/);
        if (!match) throw new Error("Invalid map assignment");
        const [_, varName, index] = match;
        const indexExp = parseExpression(index.trim(), false);
        return [`Var "${varName}"`, `FuncCall ("update_map", [Dvar (Var "${varName}"), ${indexExp}, ${parseExpression(rhs)}])`];
      }

      if (/list\s+\w+\[.+?\]/.test(lhs)) {
        const match = lhs.match(/list\s+(\w+)\[(.+?)\]/);
        if (!match) throw new Error("Invalid list assignment");
        const [_, varName, index] = match;
        const indexExp = parseExpression(index.trim(), false);
        return [`Var "${varName}"`, `FuncCall ("update_list", [Dvar (Var "${varName}"), ${indexExp}, ${parseExpression(rhs)}])`];
      }

      return [lhs, parseExpression(rhs)];
    });
}

/**
 * Converts an assignment like 'x := Plus(Dvar(Var("x")), Val(IntVal(9)))' to 'x = Plus(Dvar(Var("x_old")), Val(IntVal(9)))',
 * renaming all variables in the RHS to var_old, but only inside Dvar(Var("...")) or Dvar (Var '...').
 *
 * Example: 'y := Plus(Dvar(Var("x")), Times(Dvar(Var('y')), Dvar(Var("z"))))' => 'y = Plus(Dvar(Var("x_old")), Times(Dvar(Var('y_old')), Dvar(Var("z_old"))))'
 */
export function convertAssignmentToOldForm(variableName : string, assignment: string): string {
  if (!variableName || !assignment) return "";
  // Replace variables only inside Dvar(Var("...")) or Dvar (Var '...')
  let rhs = assignment
    // Double quotes
    .replace(/Dvar\s*\(\s*Var\s*\(\s*['"]([a-zA-Z_][a-zA-Z0-9_]*)['"]\s*\)\s*\)/g, (match, varName) => {
      return `Dvar(Var(\"${varName}_old\"))`;
    })

  return `${variableName} = ${rhs}`;
}

/**
 * Converts an assignments object {var: exp, ...} to an array of pretty assignment strings,
 * each in the form 'var = <exp_with_vars_renamed_to_old>'.
 * Uses convertAssignmentToOldForm for each entry.
 */
export function convertAssignmentsObjectToOldForm(assignments: Record<string, string>): string[] {
  if (!assignments || typeof assignments !== 'object') return [];
  return Object.entries(assignments).map(([variable, exp]) =>
    convertAssignmentToOldForm(variable, exp)
  );
}

/**
 * Converts an assignments object {var: exp, ...} to a single conjunction string,
 * e.g., 'x = ... && y = ... && ...'.
 * Uses convertAssignmentToOldForm for each entry.
 */
export function convertAssignmentsObjectToConjunction(assignments: Record<string, string>): string {
  if (!assignments || typeof assignments !== 'object') return '';
  return Object.entries(assignments)
    .map(([variable, exp]) => convertAssignmentToOldForm(variable, exp))
    .join(' && ');
}

/**
 * Substitute variables in an expression string using a substitution map.
 * For every Dvar(Var("var")) or Dvar (Var 'var'), if var is in substitutionMap, replace it with the value from the map.
 * Only replaces the innermost Dvar(Var(...)) occurrences.
 */

export function substituteVariablesInExpression(expression, substitutionMap) {
  return expression.replace(
    /Dvar\s*\(\s*Var\s*\(\s*['"]([a-zA-Z_][a-zA-Z0-9_]*)['"]\s*\)\s*\)/g,
    (match, varName) => {
      if (substitutionMap.hasOwnProperty(varName)) {
        return substitutionMap[varName]; // Replace whole Dvar(...) with the mapped value
      }
      return match; // No substitution
    }
  );
}


// Helper function to rename variables within expressions
export function renameVariablesInExpression(expression: string, variableMapping: Record<string, string>): string {
  let renamedExpression = expression;
  // Replace variable references in the format "Dvar(Var(\"variable_name\"))" with any whitespace including newlines
  Object.entries(variableMapping).forEach(([oldName, newName]) => {
    // Handle both single and double quotes with a single pattern that accounts for multiline
    const pattern = new RegExp(
      `Dvar\\s*\\(\\s*Var\\s*\\(\\s*(["'])${oldName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\1\\s*\\)\\s*\\)`,
      'gs' // 's' flag makes . match newlines
    );
    renamedExpression = renamedExpression.replace(
      pattern, 
      `Dvar(Var($1${newName}$1))`
    );
  });
  return renamedExpression;
};