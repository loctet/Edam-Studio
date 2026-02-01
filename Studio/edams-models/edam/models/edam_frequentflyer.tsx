import type { EDAMModel } from "../types";

const edam_frequentflyer: EDAMModel = {
    name: "FrequentFlyer",
    states: ["S0", "S1_plus"],
    transitions: [
        {
            from: "_",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "ar", role: "AirRep", mode: "Bottom" },
                { user: "ar", role: "FL", mode: "Bottom" },
                { user: "f", role: "AirRep", mode: "Bottom" },
                { user: "f", role: "FL", mode: "Bottom" }
            ],
            ptpVar: "ar",
            operation: "start",
            ptpVarList: ["f"],
            paramVar: {
                "_reward": "int"
            },
            assignments: {
                "rewardPerMiles": 'Dvar(Var("_reward"))',
                "totalR": 'Val(IntVal(0))',
                "indexCal": 'Val(IntVal(0))'
            },
            rhoPrime: [
                { user: "ar", role: "AirRep", mode: "Top" },
                { user: "f", role: "FL", mode: "Top" }
            ],
            to: "S0"
        },
        {
            from: "S0",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "f", role: "FL", mode: "Top" }
            ],
            ptpVar: "f",
            operation: "addMiles",
            ptpVarList: [],
            paramVar: {
                "_miles": "list_int"
            },
            assignments: {
                "miles": 'FuncCall("append_lists", [Val(StrVal("miles")); Val(StrVal("_miles"))])',
                "totalR": 'Plus(Dvar(Var("totalR")), Times(Dvar(Var("rewardPerMiles")), FuncCall("sum", [Dvar(Var("_miles"))])))'
            },
            rhoPrime: [],
            to: "S1_plus"
        },
        {
            from: "S1_plus",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "f", role: "FL", mode: "Top" }
            ],
            ptpVar: "f",
            operation: "addMiles",
            ptpVarList: [],
            paramVar: {
                "_miles": "list_int"
            },
            assignments: {
                "miles": 'FuncCall("append_lists", [Val(StrVal("miles")); Val(StrVal("_miles"))])',
                "totalR": 'Plus(Dvar(Var("totalR")), Times(Dvar(Var("rewardPerMiles")), FuncCall("sum", [Dvar(Var("_miles"))])))'
            },
            rhoPrime: [],
            to: "S1_plus"
        }
    ],
    initialState: "_",
    finalStates: ["S1_plus"],
    roles: ["AirRep", "FL"],
    variablesList: ["rewardPerMiles", "miles", "totalR", "indexCal"],
    participantsList: {},
    variables: {
        "rewardPerMiles": "int",
        "miles": "list_int",
        "totalR": "int",
        "indexCal": "int"
    }
};

export default edam_frequentflyer;

