import type { EDAMModel } from "../types";

export const edam_c1: EDAMModel = {
  name: "C1",
  states: ["q1"],
  transitions: [
      {
          from: "_",
          guard: ['Val (BoolVal(true))', []],
          rho: [],
          ptpVarList: ["p1"],
          ptpVar: "p",
          operation: "start",
          paramVar: {},
          assignments: {},
          rhoPrime: [
              { user: "p1", role: "O", mode: "Top" }
          ],
          to: "q1"
      },
      {
          from: "q1",
          guard: ['Val (BoolVal(true))', []],
          rho: [],
          ptpVarList: ["p1"],
          ptpVar: "p",
          operation: "op1",
          paramVar: {},
          assignments: {},
          rhoPrime: [
            { user: "p1", role: "O", mode: "Bottom" }
          ],
          to: "q1"
      }
  ],
  initialState: "_",
  finalStates: [],
  roles: ["O"],
  variablesList: [],
  participantsList: {},
  variables: {}
};

export const edam_c2: EDAMModel = {
  name: "C2",
  states: ["q1"],
  transitions: [
      {
          from: "_",
          guard: ['Val (BoolVal(true))', []],
          rho: [],
          ptpVarList: [],
          ptpVar: "p",
          operation: "start",
          paramVar: {},
          assignments: {},
          rhoPrime: [
              { user: "p", role: "O", mode: "Top" }
          ],
          to: "q1"
      },
      {
          from: "q1",
          guard: ['GreaterThan(Dvar(Var("a")), Dvar(Var("b")))', []],
          rho: [],
          ptpVarList: [],
          ptpVar: "p",
          operation: "op2",
          paramVar: {
              "a": "int",
              "b": "int"
          },
          assignments: {
            "f": 'Plus(Dvar(Var("f")), Dvar(Var("a")))'
          },
          rhoPrime: [],
          to: "q1"
      },
      {
          from: "q1",
          guard: ['LessThanEqual(Dvar(Var("a")), Dvar(Var("b")))', []],
          rho: [
              { user: "p", role: "O", mode: "Top" }
          ],
          ptpVarList: [],
          ptpVar: "p",
          operation: "op2",
          paramVar: {
              "a": "int",
              "b": "int"
          },
          assignments: {
            "f": 'Val(IntVal(0))'
          },
          rhoPrime: [],
          to: "q1"
      }
  ],
  initialState: "_",
  finalStates: ["q1"],
  roles: ["O"],
  variablesList: [],
  participantsList: {},
  variables: {
    "f": "int"
  }
};

export const edam_c3: EDAMModel = {
  name: "C3",
  states: ["q1", "q2"],
  transitions: [
      {
          from: "_",
          guard: ['Val (BoolVal(true))', []],
          rho: [],
          ptpVarList: [],
          ptpVar: "p",
          operation: "start",
          paramVar: {
            "y": "int",
          },
          assignments: {
            "f1": 'Dvar(Var("y"))'
          },
          rhoPrime: [],
          to: "q1"
      },
      {
          from: "q1",
          guard: [
              'GreaterThan(Dvar(Var("a")), Dvar(Var("b")))', 
              [
                  {
                    type: 'externalCall',
                    modelName: 'C2',
                    operation: 'op2',
                    args: [
                      [],
                      ['Dvar(Var("a"))', 'Dvar(Var("b"))']
                    ],
                    enabled: true
                  }
                ]
          ],
          rho: [],
          ptpVarList: [],
          ptpVar: "p",
          operation: "op3",
          paramVar: {
              "a": "int",
              "b": "int"
          },
          assignments: {
            "f1": 'Dvar(Var("b"))'
          },
          rhoPrime: [],
          to: "q2"
      }
  ],
  initialState: "_",
  finalStates: ["q2"],
  roles: [""],
  variablesList: [],
  participantsList: {},
  variables: {
    "f1": "int",
    "y": "int",
    "C2": "C2Contract"
  }
};
