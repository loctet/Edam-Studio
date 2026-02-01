import type { EDAMModel } from "../types";

const edam_basicprovenance: EDAMModel = {
    name: "BasicProvenance",
    states: ["S0", "S1", "S2"],
    transitions: [
        {
            from: "_",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVarList: [],
            ptpVar: "so",
            operation: "start",
            paramVar: {},
            assignments: {},
            rhoPrime: [
                {
                    user: "so",
                    role: "SupplyOwner",
                    mode: "Top"
                }
            ],
            to: "S0"
        },
        {
            from: "S0",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVarList: ["recipient"],
            ptpVar: "user",
            operation: "TransferResponsibility",
            paramVar: {},
            assignments: {},
            rhoPrime: [
                {
                    user: "user",
                    role: "CounterParty",
                    mode: "Bottom"
                },
                {
                    user: "recipient",
                    role: "CounterParty",
                    mode: "Top"
                }
            ],
            to: "S1"
        },
        {
            from: "S1",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                {
                    user: "user",
                    role: "CounterParty",
                    mode: "Top"
                }
            ],
            ptpVarList: ["recipient"],
            ptpVar: "user",
            operation: "TransferResponsibility",
            paramVar: {},
            assignments: {},
            rhoPrime: [
                {
                    user: "recipient",
                    role: "CounterParty",
                    mode: "Top"
                }
            ],
            to: "S1"
        },
        {
            from: "S1",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                {
                    user: "user",
                    role: "SupplyOwner",
                    mode: "Top"
                }
            ],
            ptpVarList: [],
            ptpVar: "user",
            operation: "Complete",
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S2"
        }
    ],
    initialState: "_",
    finalStates: ["S2"],
    roles: ["CounterParty", "SupplyOwner"],
    variablesList: [],
    participantsList: {},
    variables: {}
};

export default edam_basicprovenance;
