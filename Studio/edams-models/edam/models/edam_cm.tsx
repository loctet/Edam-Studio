import type { EDAMModel } from "../types";

export const edam_cm: EDAMModel = {
    name: "Cm",
    states: ["q1", "q2", "q3"],
    transitions: [
        {
            from: "_",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVar: "p",
            operation: "start",
            ptpVarList: [],
            paramVar: {
                d: "string" ,
                b: "int" 
            },
            assignments: {
                des: 'Dvar(Var("d"))',
                pr: 'Dvar(Var("b"))' 
            },
            rhoPrime: [
                { user: "p", role: "O", mode: "Top" }
            ],
            to: "q1"
        },
        {
            from: "q1",
            guard: [ 'GreaterThan(Dvar(Var("a")), Dvar(Var("off")))',
                [
                    {
                        type: 'externalCall',
                        modelName: 'C20',
                        operation: 'transferFrom',
                        args: [
                          ['PtID (Ptp "p"); Self("Cm")'],
                          ['Dvar (Var "a")']
                        ],
                        enabled: true
                      }
                ]
            ],
            rho: [],
            ptpVar: "p",
            operation: "makeO",
            ptpVarList: [],
            paramVar: {a : "int" },
            assignments: {
                off: 'Dvar(Var("a"))',
                u : 'PtID(Ptp "p")'
            },
            rhoPrime: [
                { user: "p", role: "B", mode: "Top" }
            ],
            to: "q2"
        },
        {
            from: "q2",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "p", role: "O", mode: "Top" }
            ],
            ptpVar: "p",
            operation: "accept",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "q3"
        },
        {
            from: "q2",
            guard: ['Val (BoolVal(true))', 
                [
                    {
                        type: 'externalCall',
                        modelName: 'C20',
                        operation: 'transfer',
                        args: [
                          ['Dvar(Var("u"))'],
                          ['Dvar (Var "off")']
                        ],
                        enabled: true
                      }
            ]],
            rho: [
                { user: "p", role: "O", mode: "Top" }
            ],
            ptpVar: "p",
            operation: "reject",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "q1"
        }
    ],
    initialState: "_",
    finalStates: ["q3"],
    roles: ["O", "B"],
    variablesList: ["des", "pr", "off", "u"],
    participantsList: {},
    variables: {
        des : "string",
        pr : "int",
        off : "int",
        u : "user",
        C20 : "C20",
    }
};