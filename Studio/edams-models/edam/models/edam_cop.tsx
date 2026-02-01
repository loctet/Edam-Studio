import type { EDAMModel } from "../types";


const edam_cop: EDAMModel = {
  name: "Cop",
  roles: ["O"],
  participantsList: {},
  initialState: "_",
  finalStates: ["q3"],
  variablesList: ["f_1"],
  variables: {
    "f_1": "int"
  },
  states: ["q1", "q2", "q3"],
  transitions: [
    {
      from: "_",
      guard: ['Val (BoolVal(true))', []],
      rho: [],
      ptpVarList: [],
      ptpVar: "p",
      operation: "start",
      paramVar: { },
      assignments: {},
      rhoPrime: [],
      to: "q1"
    },
    {
      from: "q1",
      guard: ['Val (BoolVal(true))', []],
      rho: [],
      ptpVarList: [],
      ptpVar: "p",
      operation: "op",
      paramVar: {
        "_a": "int",
        "_b": "int"
      },
      assignments: {
        "f_1": 'Plus(Dvar(Var("_a")), Dvar(Var("_b")))'
      },
      rhoPrime: [
        { user: "p", role: "O", mode: "Top" }
      ],
      to: "q2"
    },
    {
      from: "q2",
      guard: [
        `GreaterThan(Dvar(Var("_a")), Dvar(Var("_b")))`,
        []
      ],
      rho: [
        { user: "p", role: "O", mode: "Top" }
      ],
      ptpVarList: [],
      ptpVar: "p",
      operation: "op",
      paramVar: {
        "_a": "int",
        "_b": "int"
      },
      assignments: {
        "f_1": 'Minus(Dvar(Var("_a")), Dvar(Var("_b")))'
      },
      rhoPrime: [],
      to: "q3"
    }
  ]
};


export default edam_cop;
