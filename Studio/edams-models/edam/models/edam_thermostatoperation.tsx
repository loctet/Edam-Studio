import type { EDAMModel } from "../types";

const edam_thermostatoperation: EDAMModel = {
    name: "ThermostatOperation",
    states: ["S0", "S1"],
    transitions: [
        {
            from: "_",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "o", mode: "Bottom" },
                { user: "o", role: "i", mode: "Bottom" },
                { user: "o", role: "u", mode: "Bottom" },
                { user: "i", role: "o", mode: "Bottom" },
                { user: "i", role: "i", mode: "Bottom" },
                { user: "i", role: "u", mode: "Bottom" },
                { user: "u", role: "o", mode: "Bottom" },
                { user: "u", role: "i", mode: "Bottom" },
                { user: "u", role: "u", mode: "Bottom" }
            ],
            ptpVar: "o",
            operation: "start",
            ptpVarList: ["i", "u"],
            paramVar: {
                "_targetTemp": "int"
            },
            assignments: {
                "targetTemp": 'Dvar(Var("_targetTemp"))'
            },
            rhoPrime: [
                { user: "i", role: "i", mode: "Top" },
                { user: "u", role: "u", mode: "Top" }
            ],
            to: "S0"
        },
        {
            from: "S0",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "i", role: "i", mode: "Top" }
            ],
            ptpVar: "i",
            operation: "startThermostat",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [
                { user: "i", role: "i", mode: "Top" }
            ],
            to: "S1"
        },
        {
            from: "S1",
            guard: ['GreaterThan(Dvar(Var("_temp")), Val(IntVal(0)))', []],
            rho: [
                { user: "u", role: "u", mode: "Top" }
            ],
            ptpVar: "u",
            operation: "setTargetTemperature",
            ptpVarList: [],
            paramVar: {
                "_temp": "int"
            },
            assignments: {
                "targetTemp": 'Dvar(Var("_temp"))'
            },
            rhoPrime: [
                { user: "u", role: "u", mode: "Top" }
            ],
            to: "S1"
        },
        {
            from: "S1",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "u", role: "u", mode: "Top" }
            ],
            ptpVar: "u",
            operation: "setMode",
            ptpVarList: [],
            paramVar: {
                "_mode": "int"
            },
            assignments: {
                "mode": 'Dvar(Var("_mode"))'
            },
            rhoPrime: [
                { user: "u", role: "u", mode: "Top" }
            ],
            to: "S1"
        }
    ],
    initialState: "_",
    finalStates: ["S1"],
    roles: ["o", "i", "u"],
    variablesList: ["mode", "targetTemp"],
    participantsList: {},
    variables: {
        "targetTemp": "int",
        "mode": "int"
    }
};

export default edam_thermostatoperation;

