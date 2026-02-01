import type { EDAMTransition, EDAMModel } from "./types";

// Function to generate OCaml function representation from `pi`
export function generateOcamlFunction(rho: any[]) {
    // Group entries by user
    const groupedByUser = rho.reduce((acc: any, entry: any) => {
      if (!acc[entry.user]) {
        acc[entry.user] = [];
      }
      acc[entry.user].push(entry);
      return acc;
    }, {});
  
    // Generate the OCaml function
    let functionString = "fun p -> match p with ";
  
    Object.keys(groupedByUser).forEach((user, index) => {
      const roles = groupedByUser[user];
  
      // Add match case for the user
      functionString += `| Ptp "${user}" -> (fun  r -> `;
  
      // Add conditions for roles
      if (roles.length === 1) {
        const { role, mode } = roles[0];
        functionString += `if r = Role "${role}" then ${mode} else Unknown)`;
      } else {
        functionString += `match r with `;
        roles.forEach(({ role, mode }) => {
          functionString += `| Role "${role}" -> ${mode} `;
        });
        functionString += "| _ -> Unknown)";
      }
  
      // Add closing parenthesis and separator
      functionString += " ";
    });
  
    // Add default case
    functionString += "| _ -> (fun _ -> Unknown)";
  
    return functionString;
  }

  // Function to generate OCaml list of pairs from assignments
export function generateOcamlPairs(assignments: any[]) {
    // Map each assignment to an OCaml pair string
    const pairs = assignments.map(({ variable, expression }) => `(Var "${variable}", ${expression})`);
  
    // Return the OCaml list as a string
    return `[${pairs.join('; \n')}]`;
  }
  
  // Function to generate OCaml list of pairs from paramVar list
export function generateOcamlParamPairs(paramVarList: Record<string, string>) {
    // Map each parameter to an OCaml pair string
    const pairs = Object.entries(paramVarList || {}).map(([name, type]) => `(VarT "${type}", Var "${name}")`);
  
    // Return the OCaml list as a string
    return `[${pairs.join('; ')}]`;
  }
 
  // Function to generate OCaml list of pairs from paramVar list
export function generateOcamlPaticipantPairs(partisList: string[]) {
    // Map each parameter to an OCaml pair string
    //const pairs = partisList.split(",");
  
    if (partisList.length) 
        // Return the OCaml list as a string
        return `[Ptp "${partisList.join('"; Ptp "')}"]`;
    else 
        return "[]"
  }

export function generateEDAM(model : EDAMModel) {
  const name = model.name;
  const states = model.states;
  const transitions = model.transitions;
  const initialState = model.initialState;
  const rolesList = model.roles;
  const variablesList = model.variablesList || [];

  // Generate OCaml representation for states
  const ocamlStates = states.map(state => `State "${state}"`).join("; ");
  
  // Generate OCaml transitions
  const ocamlTransitions = transitions.map(transition => {
    let guard = "(Val (BoolVal true), [])";
    if (transition.guard && transition.guard.length === 2) {
      const [expr, calls] = transition.guard;
      guard = `(${expr || 'Val (BoolVal true)'}, [${
        calls ? calls.map(call => `(
          FuncCallEdamWrite(
            "${call.modelName}", 
            Operation("${call.operation}"), 
              [${call.args[0].join("; ")}], 
              [${call.args[1].join("; ")}]
          ), ${call.enabled})`).join('; \n') : ''
      }])`;
    }
    
    // Convert assignments object to array format expected by generateOcamlPairs
    const assignmentsArray = transition.assignments 
      ? Object.entries(transition.assignments).map(([variable, expression]) => ({variable, expression})) 
      : [];


    
    return `(
      State "${transition.from}",
      (
        ${guard},
        (${generateOcamlFunction(transition.rho || [])}),
        Ptp "${transition.ptpVar || ''}",
        Operation "${transition.operation}",
        ${generateOcamlPaticipantPairs(transition.ptpVarList || [])},
        ${generateOcamlParamPairs(transition.paramVar)},
        ${generateOcamlPairs(assignmentsArray)},
        (${generateOcamlFunction(transition.rhoPrime || [])}),
        ""
      ),
      State "${transition.to}"
    )`;
  }).join('; ');

  // Generate OCaml roles list
  const ocamlRolesList = rolesList.map(role => `Role "${role}"`).join("; ");

  // Generate OCaml variables list
  const ocamlVariablesList = variablesList.length > 0 
    ? variablesList.map(name => `Var "${name}"`).join("; ")
    : "";

  // Construct the EDAM
  return `
{
  name = "${name}";
  states = [${ocamlStates}];
  transitions = [${ocamlTransitions}];
  final_modes = []; 
  initial_state = State "${initialState}";
  roles_list = [${ocamlRolesList}];
  ptp_var_list = [];
  variables_list = [${ocamlVariablesList}]
}

let list_of_vars = ${generateOcamlParamPairs(model.variables)}
`;
}
