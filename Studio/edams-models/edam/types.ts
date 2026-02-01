export interface ExternalCall {
  type: "externalCall";
  modelName: string;
  operation: string;
  args: [any[], any[]];
  enabled: boolean;
}

export interface EDAMTransition {
  from: string;
  to: string;
  operation: string;
  guard?: [string, ExternalCall[]];
  ptpVar?: string;
  ptpVarList?: string[];
  rho?: any[];
  rhoPrime?: any[];
  paramVar?: Record<string, string>;
  assignments?: Record<string, string>;
}

export interface EDAMModel {
  name: string;
  description?: string;
  roles: string[];
  states: string[];
  initialState: string;
  finalStates?: string[];
  transitions: EDAMTransition[];
  variablesList?: string[];
  variables?: Record<string, string>;
  participantsList: Record<string, unknown>;
}

