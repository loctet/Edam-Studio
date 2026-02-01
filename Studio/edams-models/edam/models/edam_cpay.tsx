import type { EDAMModel } from "../types";


const edam_cpay: EDAMModel = {
  name: "Cpay",
  roles: ["owner", "receiver"],
  participantsList: {},
  initialState: "_",
  finalStates: ["q2"],
  variablesList: [],
  variables: {
    C20 : "C20",
  },
  states: ["q1", "q2"],
  transitions: [
    {
      from: "_",
      guard: [
        'Val (BoolVal(true))',
        [
          {
            type: 'externalCall',
            modelName: 'C20',
            operation: 'mint',
            args: [
              ['Val(IntVal(10))'],
              ['PtID(Ptp "p1")'],
              [
                '(Ptp "owner", Self)',
                '(Ptp "receiver", PtID(Ptp "p1"))',
              ]
            ],
            enabled: false
          }
        ]
      ],
      rho: [],
      ptpVarList: [],
      ptpVar: "p1",
      operation: "start",
      paramVar: {},
      assignments: {},
      rhoPrime: [],
      to: "q1"
    },
    {
      from: "q1",
      guard: [
        'Val (BoolVal(true))',
        [
          {
            type: 'externalCall',
            modelName: 'C20',
            operation: 'transferFrom',
            args: [
              ['Val(IntVal(10))'],
              ['PtID (Ptp "p1"); PtID (Ptp "p2")'],
              [
                '(Ptp "user", Self)',
                '(Ptp "recipient", PtID(Ptp "p2"))',
                '(Ptp "sender", PtID(Ptp "p1"))',
              ]
            ],
            enabled: false
          },
        ]
      ],
      rho: [],
      ptpVarList: ["p2"],
      ptpVar: "p1",
      operation: "pay",
      paramVar: {},
      assignments: {},
      rhoPrime: [],
      to: "q1"
    },
    {
      from: "q1",
      guard: [
        'Val (BoolVal(true))',
        [
          {
            type: 'externalCall',
            modelName: 'C20',
            operation: 'transferFrom',
            args: [
              ['Val(IntVal(10))'],
              ['PtID (Ptp "p1"); PtID (Ptp "p2")'],
              [
                '(Ptp "user", Self)',
                '(Ptp "recipient", PtID(Ptp "p2"))',
                '(Ptp "sender", PtID(Ptp "p1"))',
              ]
            ],
            enabled: true
          }
        ]
      ],
      rho: [],
      ptpVarList: ["p2"],
      ptpVar: "p1",
      operation: "pay",
      paramVar: {},
      assignments: {},
      rhoPrime: [],
      to: "q2"
    }
  ]
};


export default edam_cpay;
