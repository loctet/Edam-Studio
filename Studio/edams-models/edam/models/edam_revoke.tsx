import type { EDAMModel } from "../types";

export const edam_revoke: EDAMModel = {
    name: "SimpleStartRevoke",
    states: ["S0", "S1"],
    transitions: [
        {
            from: "_",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVar: "owner",
            operation: "start",
            paramVar: {},
            assignments: {
                "status": 'Val(BoolVal(true))'
            },
            rhoPrime: [
                { user: "owner", role: "Owner", mode: "Top" }
            ],
            to: "S0"
        },
        {
            from: "S0",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "owner", role: "Owner", mode: "Top" }
            ],
            ptpVar: "owner",
            operation: "revoke",
            paramVar: {p2: "pt"},
            assignments: {
                "status": 'Val(BoolVal(false))'
            },
            rhoPrime: [
                { user: "p2", role: "Owner", mode: "Top" },
                { user: "owner", role: "Owner", mode: "Bottom" }
            ],
            to: "S1"
        }
    ],
    initialState: "_",
    finalStates: ["S1"],
    roles: ["Owner"],
    variablesList: ["status"],
    participantsList: {},
    variables: {
        "status": "bool"
    }
};