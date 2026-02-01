
import type {EDAMModel} from "@edams-models/edam/types";
import { edam_models } from './Models';

// This file contains premade EDAM models from the old codebase
// Ensure all models have the participantsList property
export const premadeModels: Record<string, EDAMModel> = Object.entries(edam_models).reduce(
  (acc, [key, model]) => {
    // Ensure each model has the participantsList property
    if (!model.participantsList) {
      model.participantsList = {};
    }
    acc[key] = model;
    return acc;
  },
  {} as Record<string, EDAMModel>
);

// Convert the imported models to an array for use in the EDAMEditor
export const getPremadeModelsArray = (): EDAMModel[] => {
  return Object.values(premadeModels);
};
