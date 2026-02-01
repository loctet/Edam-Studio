import type { EDAMModel } from "../types";

const edam_defectivecounter: EDAMModel = {
    name: "DefectiveCounter",
    states: ["S0", "S1"],
    transitions: [
        {
            from: "_",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                {
                    user: "m",
                    role: "Manager",
                    mode: "Bottom"
                }
            ],
            ptpVarList: [],
            ptpVar: "m",
            operation: "start",
            paramVar: {
                "_defectives": "list_int"
            },
            assignments: {
                "defectives": 'Dvar(Var("_defectives"))'
            },
            rhoPrime: [
                {
                    user: "m",
                    role: "Manager",
                    mode: "Top"
                }
            ],
            to: "S0"
        },
        {
            from: "S0",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                {
                    user: "m",
                    role: "Manager",
                    mode: "Top"
                }
            ],
            ptpVarList: [],
            ptpVar: "m",
            operation: "computeTotal",
            paramVar: {},
            assignments: {
                "total": 'FuncCall("sum", [Dvar(Var("defectives"))])'
            },
            rhoPrime: [
                {
                    user: "m",
                    role: "Manager",
                    mode: "Top"
                }
            ],
            to: "S1"
        }
    ],
    initialState: "_",
    finalStates: ["S1"],
    roles: ["Manager"],
    variablesList: ["defectives", "total"],
    participantsList: {},
    variables: {
        "defectives": "list_int",
        "total": "int"
    }
};

export default edam_defectivecounter;
