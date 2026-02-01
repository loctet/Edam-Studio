import type { EDAMModel } from "@edams-models/edam/types";
import { edam_models as sharedEdamModels } from "@edams-models/edam";

export const edam_models: Record<string, EDAMModel> = sharedEdamModels;
