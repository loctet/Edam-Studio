import type {EDAMModel} from "@edams-models/edam/types";
import { v4 as uuidv4 } from 'uuid';

// Export existing utility functions
export * from '@edams-models/edam/modelGenerator';
export * from './expressionHelper';
export * from './textEDAMParser';

// Create and export util functions
export const createEmptyModel = (): EDAMModel => {
  const name = `New Model ${new Date().toISOString().substring(0, 19).replace(/T|:/g, '-')}`;
  return {
    name,
    roles: ['R1', 'R2'],
    states: ['S0', 'S1', 'S2'],
    initialState: 'S0',
    transitions: [],
    participantsList: {},
  };
};

export const exportModelAsJson = (model: EDAMModel): void => {
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

export const generateEdgeId = (from: string, to: string, operation: string): string => {
  return `${from}-${operation}-${to}-${uuidv4().substring(0, 8)}`;
};

export const simplifyModelForStorage = (model: EDAMModel): EDAMModel => {
  // Create a deep copy without circular references
  return JSON.parse(JSON.stringify(model));
};

// Export any other utility functions or constants
export const generateUniqueId = () => uuidv4();
