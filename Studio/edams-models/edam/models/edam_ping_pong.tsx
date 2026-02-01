import type { EDAMModel } from "../types";

export const edam_starter: EDAMModel = {
    name: "Starter",
    states: ["PongPinging", "GameFinished"],
    transitions: [
        {
            from: "_",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVar: "user",
            operation: "start",
            ptpVarList: [],
            paramVar: {
                "_gameName": "string"
            },
            assignments: {
                "gameName": 'Dvar(Var("_gameName"))'
            },
            rhoPrime: [],
            to: "PongPinging"
        },
        {
            from: "PongPinging",
            guard: [
                'GreaterThan(Dvar(Var("_currentPingPongTimes")), Val(IntVal(1)))', 
                [
                    {
                        type: 'externalCall',
                        modelName: 'Player',
                        operation: 'Ping',
                        args: [
                            [],
                            ['Minus(Dvar(Var("_currentPingPongTimes")), Val(IntVal(1)))']
                        ],
                        enabled: true
                      }
                ]
            ],
            rho: [],
            ptpVar: "user",
            operation: "Pong",
            ptpVarList: [],
            paramVar: {
                "_currentPingPongTimes": "int"
            },
            assignments: {},
            rhoPrime: [],
            to: "PongPinging"
        },
        {
            from: "PongPinging",
            guard: ['Equal(Dvar(Var("_currentPingPongTimes")), Val(IntVal(1)))', []],
            rho: [],
            ptpVar: "user",
            operation: "Pong",
            ptpVarList: [],
            paramVar: {
                "_currentPingPongTimes": "int"
            },
            assignments: {},
            rhoPrime: [],
            to: "GameFinished"
        },
        {
            from: "PongPinging",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVar: "user",
            operation: "FinishGame",
            ptpVarList: [],
            paramVar: {},
            assignments: {
                "State": 'Val(StrVal("GameFinished"))'
            },
            rhoPrime: [],
            to: "GameFinished"
        }
    ],
    initialState: "_",
    finalStates: ["GameFinished"],
    roles: [],
    variablesList: ["PingPongTimes", "currentPingPongTimes", "gameName"],
    participantsList: {},
    variables: {
        "PingPongTimes": "int",
        "currentPingPongTimes": "int",
        "gameName": "string"
    }
};

export const edam_player: EDAMModel = {
    name: "Player",
    states: ["_", "Pingponging", "GameFinished"],
    transitions: [
        {
            from: "_",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVar: "user",
            operation: "start",
            ptpVarList: [],
            paramVar: {
                "_gameName": "string"
            },
            assignments: {
                "gameName": 'Dvar(Var("_gameName"))'
            },
            rhoPrime: [],
            to: "Pingponging"
        },
        {
            from: "Pingponging",
            guard: [
                'GreaterThan(Dvar(Var("_currentPingPongTimes")), Val(IntVal(1)))',
                [
                    {
                        type: 'externalCall',
                        modelName: 'Starter',
                        operation: 'Pong',
                        args: [
                            [],
                            ['Minus(Dvar(Var("_currentPingPongTimes")), Val(IntVal(1)))']
                        ],
                        enabled: true
                      }
                ]
            ],
            rho: [],
            ptpVar: "user",
            operation: "Ping",
            ptpVarList: [],
            paramVar: {
                "_currentPingPongTimes": "int"
            },
            assignments: {},
            rhoPrime: [],
            to: "Pingponging"
        },
        {
            from: "Pingponging",
            guard: ['Equal(Dvar(Var("_currentPingPongTimes")), Val(IntVal(1)))', []],
            rho: [],
            ptpVar: "user",
            operation: "Ping",
            ptpVarList: [],
            paramVar: {
                "_currentPingPongTimes": "int"
            },
            assignments: {},
            rhoPrime: [],
            to: "GameFinished"
        },
        {
            from: "Pingponging",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVar: "user",
            operation: "FinishGame",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "GameFinished"
        }
    ],
    initialState: "_",
    finalStates: ["GameFinished"],
    roles: [],
    variablesList: ["PingPongTimes", "currentPingPongTimes", "gameName"],
    participantsList: {},
    variables: {
        "PingPongTimes": "int",
        "currentPingPongTimes": "int",
        "gameName": "string"
    }
};

