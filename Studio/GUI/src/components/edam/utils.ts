
import type {EDAMModel, EDAMTransition} from "@edams-models/edam/types";

/**
 * Validate a EDAM model
 * @param model The model to validate
 * @returns Array of validation errors, empty if valid
 */
export const validateModel = (model: EDAMModel): string[] => {
  const errors: string[] = [];
  
  // Check required fields
  if (!model.name) errors.push("Model name is required");
  if (!model.roles || model.roles.length === 0) errors.push("At least one role is required");
  if (!model.states || model.states.length === 0) errors.push("At least one state is required");
  if (!model.initialState) errors.push("Initial state is required");
  if (!model.transitions) errors.push("Transitions array is required");
  
  const states = ["_", ...model.states]; // add initial state to the list of states
  
  // Check that initial state exists
  if (model.initialState && model.initialState !== "_") {
    errors.push(`Initial state '${model.initialState}' is not equal to '_'`);
  }

  // Check that initial state exists
  if (model.initialState && states && !states.includes(model.initialState)) {
    errors.push(`Initial state '${model.initialState}' is not in the states list`);
  }
  
  // Check that final states exist
  if (model.finalStates && states) {
    model.finalStates.forEach(finalState => {
      if (!states.includes(finalState)) {
        errors.push(`Final state '${finalState}' is not in the states list`);
      }
    });
  }
  
  // Check transitions
  if (model.transitions && states) {
    // Separate start transitions from other transitions
    const startTransitions = model.transitions.filter(t => t.operation === "start");
    const otherTransitions = model.transitions.filter(t => t.operation !== "start");
    
    // Validate start transitions (OCaml logic)
    startTransitions.map((startTransition) => {
      if (startTransition.from !== "_") {
        errors.push(`Start transition must be from "_" state, found '${startTransition.from}'`);
      }
      if (startTransition.to === "_") {
        errors.push(`Start transition must not go to "_" state`);
      }
    })
    
    // Validate other transitions (OCaml logic)
    otherTransitions.forEach((transition, index) => {
      if (transition.from === "_") {
        errors.push(`Transition ${index}: Non-start transitions cannot be from "_" state`);
      }
      if (transition.to === "_") {
        errors.push(`Transition ${index}: Non-start transitions cannot go to "_" state`);
      }
    });

    // Original transition validation
    model.transitions.forEach((transition, index) => {
      // Check from state
      if (!transition.from) {
        errors.push(`Transition ${index}: 'from' state is required`);
      } else if (!states.includes(transition.from)) {
        errors.push(`Transition ${index}: 'from' state '${transition.from}' is not in the states list`);
      }
      
      // Check to state
      if (!transition.to) {
        errors.push(`Transition ${index}: 'to' state is required`);
      } else if (!states.includes(transition.to)) {
        errors.push(`Transition ${index}: 'to' state '${transition.to}' is not in the states list`);
      }
      
      // Check operation
      if (!transition.operation) {
        errors.push(`Transition ${index}: 'operation' is required`);
      }
    });
  }
  
  return errors;
};

/**
 * Create an empty EDAM model template
 * @returns An empty EDAM model
 */
export const createEmptyModel = (): EDAMModel => {
  return {
    name: "New Model",
    roles: ["Role1", "Role2"],
    states: ["S0", "S1"],
    initialState: "S0",
    finalStates: ["S1"],
    transitions: [
      {
        from: "S0",
        to: "S1",
        operation: "operation",
        ptpVar: "p1"
      }
    ],
    participantsList: {}  // Added missing required property
  };
};

/**
 * Export model as JSON file
 * @param model The model to export
 */
export const exportModelAsJson = (model: EDAMModel) => {
  const jsonString = JSON.stringify(model, null, 2);
  const blob = new Blob([jsonString], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  
  const a = document.createElement('a');
  a.href = url;
  a.download = `${model.name.replace(/\s+/g, '_')}.json`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
};

/**
 * Format transition label
 * @param transition The transition to format
 * @returns Formatted label
 */
export const formatTransitionLabel = (transition: EDAMTransition): string => {
  let label = transition.operation;
  
  if (transition.ptpVar) {
    label += `\n(${transition.ptpVar})`;
  }
  
  return `${transition.ptpVar} ▷ ${transition.operation}`;
};
