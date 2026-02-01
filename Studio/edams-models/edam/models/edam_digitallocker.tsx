import type { EDAMModel } from "../types";

const edam_digital_locker: EDAMModel = {
    name: "DigitalLocker",
    states: ["S0", "S1", "S2", "S3", "S3P", "S4", "S5"],
    transitions: [
        {
            from: "_",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVar: "o",
            operation: "start",
            ptpVarList: ["ba"],
            paramVar: {
                "_lock_id": "string"
            },
            assignments: {
                "lock_id": 'Dvar(Var("_lock_id"))'
            },
            rhoPrime: [
                { user: "o", role: "Owner", mode: "Top" },
                { user: "ba", role: "Banker", mode: "Top" }
            ],
            to: "S0"
        },
        {
            from: "S0",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "ba", role: "Banker", mode: "Unknown" }
            ],
            ptpVar: "ba",
            operation: "BeginReview",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [
                { user: "ba", role: "Banker", mode: "Top" }
            ],
            to: "S1"
        },
        {
            from: "S1",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "ba", role: "Banker", mode: "Top" }
            ],
            ptpVar: "ba",
            operation: "UploadDocument",
            ptpVarList: [],
            paramVar: {
                "_lock_id": "string",
                "_image": "string"
            },
            assignments: {
                "image": 'Dvar(Var("_image"))',
                "lock_id": 'Dvar(Var("_lock_id"))'
            },
            rhoPrime: [
                { user: "ba", role: "Banker", mode: "Top" }
            ],
            to: "S2"
        },
        {
            from: "S2",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "tpr", role: "TrdParty", mode: "Unknown" }
            ],
            ptpVar: "tpr",
            operation: "RequestLockAccess",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [
                { user: "tpr", role: "TrdParty", mode: "Top" }
            ],
            to: "S4"
        },
        {
            from: "S2",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "ba", role: "Banker", mode: "Top" }
            ],
            ptpVar: "ba",
            operation: "Terminate",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [
                { user: "cau", role: "CAU", mode: "Bottom" }
            ],
            to: "S5"
        },
        {
            from: "S3",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "Owner", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "RevokeAccessLock",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [
                { user: "cau", role: "CAU", mode: "Bottom" }
            ],
            to: "S2"
        },
        {
            from: "S3",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "cau", role: "CAU", mode: "Top" }
            ],
            ptpVar: "cau",
            operation: "ReleaseLockAccess",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [
                { user: "cau", role: "CAU", mode: "Bottom" },
                { user: "tpr", role: "TrdParty", mode: "Bottom" }
            ],
            to: "S2"
        },
        {
            from: "S3",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "ba", role: "Banker", mode: "Top" }
            ],
            ptpVar: "ba",
            operation: "Terminate",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [
                { user: "cau", role: "CAU", mode: "Bottom" }
            ],
            to: "S5"
        },
        {
            from: "S4",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "Owner", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "RejectSharingLock",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [
                { user: "cau", role: "CAU", mode: "Bottom" }
            ],
            to: "S2"
        },
        {
            from: "S4",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "Owner", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "AcceptSharingLock",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [
                { user: "cau", role: "CAU", mode: "Top" }
            ],
            to: "S3P"
        },
        {
            from: "S3P",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "o", role: "Owner", mode: "Top" }
            ],
            ptpVar: "o",
            operation: "ShareW3rdP",
            ptpVarList: ["tpr"],
            paramVar: {},
            assignments: {},
            rhoPrime: [
                { user: "tpr", role: "TrdParty", mode: "Top" }
            ],
            to: "S3"
        }
    ],
    initialState: "_",
    finalStates: ["S2", "S3", "S3P", "S4", "S5"],
    roles: ["Owner", "Banker", "TrdParty", "CAU"],
    variablesList: ["lock_id", "image"],
    participantsList: {},
    variables: {
        "lock_id": "string",
        "image": "string"
    }
};

export default edam_digital_locker;
