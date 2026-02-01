import type { EDAMModel } from "../types";

const edam_simplewallet: EDAMModel = {
    name: "Simplewallet",
    states: ["q1", "q2", "q3"],
    transitions: [
        {
            from: "_",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVar: "user",
            operation: "start",
            ptpVarList: [],
            paramVar: {},
            assignments: {
                "balance": 'Val(IntVal(0))'
            },
            rhoPrime: [
                { user: "user", role: "user", mode: "Top" }
            ],
            to: "q1"
        },
        {
            from: "q1",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "user", role: "user", mode: "Top" }
            ],
            ptpVar: "user",
            operation: "Deposit",
            ptpVarList: [],
            paramVar: {
                "_amount": "int"
            },
            assignments: {
                "balance": 'Plus(Dvar(Var("balance")), Dvar(Var("_amount")))'
            },
            rhoPrime: [],
            to: "q2"
        },
        {
            from: "q2",
            guard: ['And(GreaterThanEqual(Dvar(Var("balance")), Dvar(Var("_amount"))), GreaterThan(Dvar(Var("_amount")), Val(IntVal(0))))', []],
            rho: [
                { user: "user", role: "user", mode: "Top" }
            ],
            ptpVar: "user",
            operation: "Withdraw",
            ptpVarList: [],
            paramVar: {
                "_amount": "int"
            },
            assignments: {
                "balance": 'Minus(Dvar(Var("balance")), Dvar(Var("_amount")))'
            },
            rhoPrime: [],
            to: "q2"
        },
        {
            from: "q2",
            guard: ['Equal(Dvar(Var("balance")), Val(IntVal(0)))', []],
            rho: [
                { user: "user", role: "user", mode: "Top" }
            ],
            ptpVar: "user",
            operation: "EndWallet",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "q3"
        }
    ],
    initialState: "_",
    finalStates: ["q3"],
    roles: ["user"],
    variablesList: ["balance"],
    participantsList: {},
    variables: {
        "balance": "int"
    }
};

export default edam_simplewallet;