import type { EDAMModel } from "../types";

export const edam_simplemarketplace:EDAMModel = {
    name: "Simplemarketplace",
    states: ["q1", "q2", "q3"],
    transitions: [
        {
            from: "_",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "ptpO", role: "O", mode: "Bottom" },
                { user: "ptpO", role: "B", mode: "Bottom" }
            ],
            ptpVar: "ptpO",
            operation: "start",
            ptpVarList: [],
            paramVar: {
                "_des": "string",
                "_price": "int"
            },
            assignments: {
                "des": 'Dvar(Var("_des"))',
                "pr": 'Dvar(Var("_price"))'
            },
            rhoPrime: [
                { user: "ptpO", role: "O", mode: "Top" }
            ],
            to: "q1"
        },
        {
            from: "q1",
            guard: ['GreaterThan(Dvar(Var("_offer")), Dvar(Var("offer")))', []],
            rho: [],
            ptpVar: "ptpB",
            operation: "makeOffer",
            ptpVarList: [],
            paramVar: {
                "_offer": "int"
            },
            assignments: {
                "offer": 'Dvar(Var("_offer"))'
            },
            rhoPrime: [
                { user: "ptpB", role: "B", mode: "Top" }
            ],
            to: "q2"
        },
        {
            from: "q2",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "ptpO", role: "O", mode: "Top" }
            ],
            ptpVar: "ptpO",
            operation: "acceptOffer",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "q3"
        },
        {
            from: "q2",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "ptpO", role: "O", mode: "Top" }
            ],
            ptpVar: "ptpO",
            operation: "rejectOffer",
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
    variablesList: ["des", "pr", "offer"],
    participantsList: {},
    variables: {
        "des": "string",
        "pr": "int",
        "offer": "int"
    }
};
