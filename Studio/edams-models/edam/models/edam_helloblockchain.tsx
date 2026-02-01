import type { EDAMModel } from "../types";

const edam_helloblockchain: EDAMModel = {
    name: "HelloBlockchain",
    states: ["Request", "Respond"],
    transitions: [
        {
            from: "_",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVarList: [],
            ptpVar: "user",
            operation: "start",
            paramVar: {
                "_requestMessage": "string"
            },
            assignments: {
                "RequestMessage": 'Dvar(Var("_requestMessage"))'
            },
            rhoPrime: [
                {
                    user: "user",
                    role: "Requestor",
                    mode: "Top"
                }
            ],
            to: "Request"
        },
        {
            from: "Request",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                {
                    user: "user",
                    role: "Requestor",
                    mode: "Top"
                }
            ],
            ptpVarList: [],
            ptpVar: "user",
            operation: "SendRequest",
            paramVar: {
                "_requestMessage": "string"
            },
            assignments: {
                "RequestMessage": 'Dvar(Var("_requestMessage"))'
            },
            rhoPrime: [],
            to: "Respond"
        },
        {
            from: "Respond",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVarList: [],
            ptpVar: "user",
            operation: "SendResponse",
            paramVar: {
                "_responseMessage": "string"
            },
            assignments: {
                "ResponseMessage": 'Dvar(Var("_responseMessage"))'
            },
            rhoPrime: [
                {
                    user: "user",
                    role: "Responder",
                    mode: "Top"
                }
            ],
            to: "Request"
        }
    ],
    initialState: "_",
    finalStates: ["Respond"],
    roles: ["Requestor", "Responder"],
    variablesList: ["RequestMessage", "ResponseMessage"],
    participantsList: {},
    variables: {
        "RequestMessage": "string",
        "ResponseMessage": "string"
    }
};

export default edam_helloblockchain;
