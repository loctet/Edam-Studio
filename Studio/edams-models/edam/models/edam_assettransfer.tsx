import type { EDAMModel } from "../types";

const edam_assettransfer: EDAMModel = {
    name: "AssetTransfer",
    states: ["S0", "S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9"],
    transitions: [
        {
            from: "_",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Bottom" },
                { user: "o", role: "B", mode: "Bottom" },
                { user: "o", role: "I", mode: "Bottom" },
                { user: "o", role: "A", mode: "Bottom" }
            ],
            ptpVar: "o",
            operation: "start",
            ptpVarList: [],
            paramVar: {
                "_price": "int"
            },
            assignments: {
                "AskingPrice": 'Dvar(Var("_price"))',
                "OfferPrice": 'Val(IntVal(0))'
            },
            rhoPrime: [
                { user: "o", role: "O", mode: "Top" }
            ],
            to: "S0"
        },
        {
            from: "S0",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVar: "b",
            operation: "makeOffer",
            ptpVarList: ["i", "a"],
            paramVar: {
                "_price": "int"
            },
            assignments: {
                "OfferPrice": 'Dvar(Var("_price"))'
            },
            rhoPrime: [
                { user: "b", role: "B", mode: "Top" },
                { user: "i", role: "I", mode: "Top" },
                { user: "a", role: "A", mode: "Top" }
            ],
            to: "S1"
        },
        {
            from: "S0",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "terminate",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S9"
        },
        {
            from: "S0",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "modify",
            ptpVarList: [],
            paramVar: {
                "_description": "string",
                "_price": "int"
            },
            assignments: {
                "AskingPrice": 'Dvar(Var("_price"))',
                "description": 'Dvar(Var("_description"))'
            },
            rhoPrime: [],
            to: "S0"
        },
        {
            from: "S1",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "b", role: "B", mode: "Top" }
            ],
            ptpVar: "b",
            operation: "modifyOffer",
            ptpVarList: [],
            paramVar: {
                "_price": "int"
            },
            assignments: {
                "OfferPrice": 'Dvar(Var("_price"))'
            },
            rhoPrime: [],
            to: "S1"
        },
        {
            from: "S1",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "reject",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S0"
        },
        {
            from: "S1",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "acceptOffer",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S2"
        },
        {
            from: "S1",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "b", role: "B", mode: "Top" }
            ],
            ptpVar: "b",
            operation: "RescindOffer",
            ptpVarList: [],
            paramVar: {},
            assignments: {
                "OfferPrice": 'Val(IntVal(0))'
            },
            rhoPrime: [
                { user: "b", role: "B", mode: "Bottom" }
            ],
            to: "S0"
        },
        {
            from: "S1",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "terminate",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S9"
        },
        {
            from: "S2",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "reject",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S0"
        },
        {
            from: "S2",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "b", role: "B", mode: "Top" }
            ],
            ptpVar: "b",
            operation: "RescindOffer",
            ptpVarList: [],
            paramVar: {},
            assignments: {
                "OfferPrice": 'Val(IntVal(0))'
            },
            rhoPrime: [
                { user: "b", role: "B", mode: "Bottom" }
            ],
            to: "S0"
        },
        {
            from: "S2",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "terminate",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S9"
        },
        {
            from: "S2",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "i", role: "I", mode: "Top" }
            ],
            ptpVar: "i",
            operation: "inspect",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S3"
        },
        {
            from: "S2",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "a", role: "A", mode: "Top" }
            ],
            ptpVar: "a",
            operation: "MarkAppraised",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S7"
        },
        {
            from: "S3",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "reject",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S0"
        },
        {
            from: "S3",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "b", role: "B", mode: "Top" }
            ],
            ptpVar: "b",
            operation: "RescindOffer",
            ptpVarList: [],
            paramVar: {},
            assignments: {
                "OfferPrice": 'Val(IntVal(0))'
            },
            rhoPrime: [
                { user: "b", role: "B", mode: "Bottom" }
            ],
            to: "S0"
        },
        {
            from: "S3",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "terminate",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S9"
        },
        {
            from: "S3",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "a", role: "A", mode: "Top" }
            ],
            ptpVar: "a",
            operation: "MarkAppraised",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S4"
        },
        {
            from: "S4",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "reject",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S0"
        },
        {
            from: "S4",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "b", role: "B", mode: "Top" }
            ],
            ptpVar: "b",
            operation: "RescindOffer",
            ptpVarList: [],
            paramVar: {},
            assignments: {
                "OfferPrice": 'Val(IntVal(0))'
            },
            rhoPrime: [
                { user: "b", role: "B", mode: "Bottom" }
            ],
            to: "S0"
        },
        {
            from: "S4",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "terminate",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S9"
        },
        {
            from: "S4",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "acceptOffer",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S5"
        },
        {
            from: "S4",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "b", role: "B", mode: "Top" }
            ],
            ptpVar: "b",
            operation: "accept",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S8"
        },
        {
            from: "S5",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "b", role: "B", mode: "Top" }
            ],
            ptpVarList: [],
            ptpVar: "b",
            operation: "RescindOffer",
            paramVar: {},
            assignments: {
                "OfferPrice": 'Val(IntVal(0))'
            },
            rhoPrime: [
                { user: "b", role: "B", mode: "Bottom" }
            ],
            to: "S0"
        },
        {
            from: "S5",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "b", role: "B", mode: "Top" }
            ],
            ptpVarList: [],
            ptpVar: "b",
            operation: "accept",
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S6"
        },
        {
            from: "S7",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVarList: [],
            ptpVar: "o",
            operation: "reject",
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S0"
        },
        {
            from: "S7",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "b", role: "B", mode: "Top" }
            ],
            ptpVarList: [],
            ptpVar: "b",
            operation: "RescindOffer",
            paramVar: {},
            assignments: {
                "OfferPrice": 'Val(IntVal(0))'
            },
            rhoPrime: [
                { user: "b", role: "B", mode: "Bottom" }
            ],
            to: "S0"
        },
        {
            from: "S7",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVarList: [],
            ptpVar: "o",
            operation: "terminate",
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S9"
        },
        {
            from: "S7",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "i", role: "I", mode: "Top" }
            ],
            ptpVarList: [],
            ptpVar: "i",
            operation: "inspect",
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S4"
        },
        {
            from: "S8",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVarList: [],
            ptpVar: "o",
            operation: "terminate",
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S9"
        },
        {
            from: "S8",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "b", role: "B", mode: "Top" }
            ],
            ptpVarList: [],
            ptpVar: "b",
            operation: "RescindOffer",
            paramVar: {},
            assignments: {
                "OfferPrice": 'Val(IntVal(0))'
            },
            rhoPrime: [
                { user: "b", role: "B", mode: "Bottom" }
            ],
            to: "S0"
        },
        {
            from: "S8",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "O", mode: "Top" }
            ],
            ptpVarList: [],
            ptpVar: "o",
            operation: "accept",
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "S6"
        }
    ],
    initialState: "_",
    finalStates: ["S9"],
    roles: ["O", "B", "I", "A"],
    variablesList: ["description", "AskingPrice", "OfferPrice"],
    participantsList: {},
    variables: {
        "description": "string",
        "AskingPrice": "int",
        "OfferPrice": "int"
    }
};

export default edam_assettransfer;
