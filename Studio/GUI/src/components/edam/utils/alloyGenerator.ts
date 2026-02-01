/**
 * Alloy Generator for EDAM Models
 * 
 * Converts EDAM models to Alloy Analyzer format for formal verification
 */

import type {EDAMModel, EDAMTransition} from "@edams-models/edam/types";

/**
 * Convert EDAM variable type to Alloy type
 */
function convertVarTypeToAlloy(varType: string): string {
    const typeMap: Record<string, string> = {
        "int": "Int",
        "string": "String",
        "map_address_int": "Participant -> one Int",
        "map_map_address_address_int": "Participant -> Participant -> one Int",
        "map_address_string": "Participant -> one String",
    };
    
    return typeMap[varType] || "Int"; // Default to Int
}

/**
 * Generate Alloy signature for variables
 */
function generateVariableSignatures(model: EDAMModel): string {
    if (!model.variables) return "";
    
    const vars = Object.entries(model.variables);
    if (vars.length === 0) return "";
    
    return `
sig VarStore {
${vars.map(([name, type]) => {
    const alloyType = convertVarTypeToAlloy(type);
    const fieldName = name.replace(/([A-Z])/g, '_$1').toLowerCase();
    return `    ${fieldName}: one ${alloyType}`;
}).join(',\n')}
}`;
}

/**
 * Generate Alloy states
 */
function generateStates(model: EDAMModel): string {
    const states = model.states.map(s => `"${s}"`).join(", ");
    return `states = [${states}]`;
}

/**
 * Generate Alloy transition signature
 */
function generateTransitionSignature(transition: EDAMTransition, index: number): string {
    const transitionName = `Transition${index}`;
    const params = transition.paramVar ? Object.keys(transition.paramVar) : [];
    
    let sig = `
sig ${transitionName} extends Transition {
    operation: one String
`;
    
    // Add parameters
    params.forEach(param => {
        const paramType = transition.paramVar![param];
        const alloyType = paramType === "int" ? "Int" : "String";
        sig += `    ${param}: one ${alloyType}\n`;
    });
    
    // Add participants
    if (transition.ptpVarList && transition.ptpVarList.length > 0) {
        transition.ptpVarList.forEach((ptp, idx) => {
            sig += `    participant${idx}: one Participant  // ${ptp}\n`;
        });
    }
    
    sig += `} {\n`;
    sig += `    operation = "${transition.operation}"\n`;
    sig += `    from.name = "${transition.from}"\n`;
    sig += `    to.name = "${transition.to}"\n`;
    
    // Add guard constraints (simplified)
    if (transition.guard && transition.guard[0]) {
        const guardStr = transition.guard[0];
        // Extract simple constraints (this is simplified - full parser needed)
        if (guardStr.includes("GreaterThanEqual")) {
            // Would need to parse the guard expression properly
            sig += `    // Guard: ${guardStr}\n`;
        } else if (guardStr.includes("BoolVal(true)")) {
            sig += `    // Guard: true\n`;
        }
    }
    
    sig += `}`;
    
    return sig;
}

/**
 * Generate Alloy model from EDAM
 */
export function generateAlloyModel(model: EDAMModel): string {
    const states = generateStates(model);
    const roles = model.roles.map(r => `"${r}"`).join(", ");
    const initialState = model.initialState;
    const finalStates = model.finalStates?.map(s => `"${s}"`).join(", ") || "none";
    
    // Generate transition signatures
    const transitionSigs = model.transitions
        .map((t, idx) => generateTransitionSignature(t, idx))
        .join("\n\n");
    
    // Generate variable store
    const varStore = generateVariableSignatures(model);
    
    return `
/*
 * Alloy Model Generated from EDAM: ${model.name}
 * 
 * This model was automatically generated from a EDAM specification.
 * Manual refinement may be needed for complex guards and assignments.
 */

// ============================================================================
// Core Signatures (include from base model)
// ============================================================================

sig State {
    name: one String
}

sig Participant {
    id: one Int
}

sig Role {
    name: one String
}

enum Mode { Top, Bottom }

sig Permission {
    participant: one Participant,
    role: one Role,
    mode: one Mode
}

abstract sig Transition {
    from: one State,
    to: one State,
    operation: one String,
    principal: one Participant,
    participants: set Participant,
    prePermissions: set Permission,
    postPermissions: set Permission
}

${varStore}

// ============================================================================
// Transition Definitions
// ============================================================================

${transitionSigs}

// ============================================================================
// EDAM Model
// ============================================================================

sig EDAM {
    name: one String,
    states: set State,
    initialState: one State,
    finalStates: set State,
    roles: set Role,
    transitions: set Transition
}

// ============================================================================
// System State
// ============================================================================

sig SystemState {
    currentState: one State,
    vars: one VarStore,
    activePermissions: set Permission,
    step: one Int
}

// ============================================================================
// Facts
// ============================================================================

fact EDAMStructure {
    one d: EDAM {
        d.name = "${model.name}"
        ${states}
        d.initialState.name = "${initialState}"
        d.finalStates = ${finalStates === "none" ? "none" : `[${finalStates}]`}
        d.roles.name = [${roles}]
    }
}

// ============================================================================
// Run Command
// ============================================================================

run {
    one d: EDAM | d.name = "${model.name}"
} for 5 but 1 EDAM, ${model.states.length + 1} State, ${model.roles.length} Role, 3 Participant
`;
}

/**
 * Generate a simplified Alloy model focusing on structure
 */
export function generateSimpleAlloyModel(model: EDAMModel): string {
    return `
/*
 * Simplified Alloy Model for ${model.name}
 * 
 * This is a structural representation. Add transition effects and guards manually.
 */

sig State {
    name: one String
}

sig Role {
    name: one String
}

sig Participant {
    id: one Int
}

sig Transition {
    from: one State,
    to: one State,
    operation: one String
}

sig EDAM {
    name: one String,
    states: set State,
    initialState: one State,
    finalStates: set State,
    roles: set Role,
    transitions: set Transition
}

fact ${model.name}Model {
    one d: EDAM {
        d.name = "${model.name}"
        d.states.name = [${model.states.map(s => `"${s}"`).join(", ")}]
        d.initialState.name = "${model.initialState}"
        d.finalStates.name = [${model.finalStates?.map(s => `"${s}"`).join(", ") || ""}]
        d.roles.name = [${model.roles.map(r => `"${r}"`).join(", ")}]
        d.transitions.operation = [${model.transitions.map(t => `"${t.operation}"`).join(", ")}]
    }
}

run {
    one d: EDAM | d.name = "${model.name}"
} for 5
`;
}

