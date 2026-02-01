import type { EDAMModel } from "../types";

const edam_refrigeratedtransport: EDAMModel = {
    name: "RefrigeratedTransport",
    states: ["S0", "S1", "SFail", "Success"],
    transitions: [
        {
            from: "_",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVar: "ptpI",
            operation: "start",
            ptpVarList: ["ptpO", "ptpW"],
            paramVar: {
                "_MinHum": "int",
                "_MaxHum": "int",
                "_MinTem": "int",
                "_MaxTem": "int",
                "_hum": "int",
                "_tem": "int"
            },
            assignments: {
                "MaxHum": 'Dvar(Var("_MaxHum"))',
                "MinHum": 'Dvar(Var("_MinHum"))',
                "MaxTem": 'Dvar(Var("_MaxTem"))',
                "MinTem": 'Dvar(Var("_MinTem"))',
                "hum": 'Dvar(Var("_hum"))',
                "tem": 'Dvar(Var("_tem"))'
            },
            rhoPrime: [
                { user: "ptpI", role: "CP", mode: "Top" },
                { user: "ptpI", role: "ICP", mode: "Top" },
                { user: "ptpO", role: "SO", mode: "Top" },
                { user: "ptpW", role: "W", mode: "Top" }
            ],
            to: "S0"
        },
        {
            from: "S0",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "user", role: "ICP", mode: "Top" },
                { user: "user", role: "CP", mode: "Top" },
                { user: "ptpQ", role: "CP", mode: "Bottom"}
            ],
            ptpVar: "user",
            operation: "transf",
            ptpVarList: ["ptpQ"],
            paramVar: {},
            assignments: {},
            rhoPrime: [
                { user: "user", role: "PCP", mode: "Top" },
                { user: "user", role: "CP", mode: "Bottom"},
                { user: "ptpQ", role: "CP", mode: "Top" }
            ],
            to: "S1"
        },
        {
            from: "S0",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "user", role: "ICP", mode: "Top" },
                { user: "ptpQ", role: "ICP", mode: "Top" }
            ],
            ptpVar: "user",
            operation: "transf",
            ptpVarList: ["ptpQ"],
            paramVar: {},
            assignments: {},
            rhoPrime: [
                { user: "user", role: "PCP", mode: "Top" },
                { user: "user", role: "CP", mode: "Top" }
            ],
            to: "S1"
        },/*
        {
            from: "S1",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "user", role: "CP", mode: "Top" }
            ],
            ptpVar: "user",
            operation: "transf",
            ptpVarList: ["ptpQ"],
            paramVar: {},
            assignments: {},
            rhoPrime: [
                { user: "user", role: "PCP", mode: "Top" },
                { user: "user", role: "CP", mode: "Bottom" },
                { user: "ptpQ", role: "CP", mode: "Top" }
            ],
            to: "S1"
        }, */
        {
            from: "S1",
            guard: ['Val (BoolVal(true))', []],
            rho: [
                { user: "user", role: "CP", mode: "Top" },
                { user: "ptpQ", role: "CP", mode: "Top" }
            ],
            ptpVar: "user",
            operation: "transf",
            ptpVarList: ["ptpQ"],
            paramVar: {},
            assignments: {},
            rhoPrime: [
                { user: "user", role: "PCP", mode: "Top" }
            ],
            to: "S1"
        },
        {
            from: "S0",
            guard: [`
            And(
                And(
                    And(
                        LessThanEqual(Dvar(Var("_hum")), Dvar(Var("MaxHum"))),
                        GreaterThanEqual(Dvar(Var("_hum")), Dvar(Var("MinHum")))
                    ),
                    And(
                        LessThanEqual(Dvar(Var("_tem")), Dvar(Var("MaxTem"))),
                        GreaterThanEqual(Dvar(Var("_tem")), Dvar(Var("MinTem")))
                    )
                ),
                And(
                    GreaterThanEqual(Dvar(Var("_hum")), Val(IntVal(0))),
                    GreaterThanEqual(Dvar(Var("_tem")), Val(IntVal(0)))
                )
            )`, []],
            rho: [],
            ptpVar: "ptpD",
            operation: "ingestTelemetry",
            ptpVarList: [],
            paramVar: {
                "_hum": "int",
                "_tem": "int"
            },
            assignments: {
                "tem": 'Dvar(Var("_tem"))',
                "hum": 'Dvar(Var("_hum"))'
            },
            rhoPrime: [],
            to: "S0"
        },
        {
            from: "S0",
            guard: [`
            And(
                Not(
                    And(
                        And(
                            LessThanEqual(Dvar(Var("_hum")), Dvar(Var("MaxHum"))),
                            GreaterThanEqual(Dvar(Var("_hum")), Dvar(Var("MinHum")))
                        ),
                        And(
                            LessThanEqual(Dvar(Var("_tem")), Dvar(Var("MaxTem"))),
                            GreaterThanEqual(Dvar(Var("_tem")), Dvar(Var("MinTem")))
                        )
                    )
                ),
                And(
                    GreaterThanEqual(Dvar(Var("_hum")), Val(IntVal(0))),
                    GreaterThanEqual(Dvar(Var("_tem")), Val(IntVal(0)))
                )
            )`, []],
            rho: [],
            ptpVar: "ptpD",
            operation: "ingestTelemetry",
            ptpVarList: [],
            paramVar: {
                "_hum": "int",
                "_tem": "int"
            },
            assignments: {
                "tem": 'Dvar(Var("_tem"))',
                "hum": 'Dvar(Var("_hum"))'
            },
            rhoPrime: [],
            to: "SFail"
        },
        {
            from: "S1",
            guard: [`
            And(
                And(
                    And(
                        LessThanEqual(Dvar(Var("_hum")), Dvar(Var("MaxHum"))),
                        GreaterThanEqual(Dvar(Var("_hum")), Dvar(Var("MinHum")))
                    ),
                    And(
                        LessThanEqual(Dvar(Var("_tem")), Dvar(Var("MaxTem"))),
                        GreaterThanEqual(Dvar(Var("_tem")), Dvar(Var("MinTem")))
                    )
                ),
                And(
                    GreaterThanEqual(Dvar(Var("_hum")), Val(IntVal(0))),
                    GreaterThanEqual(Dvar(Var("_tem")), Val(IntVal(0)))
                )
            )`, []],
            rho: [],
            ptpVar: "ptpD",
            operation: "ingestTelemetry",
            ptpVarList: [],
            paramVar: {
                "_hum": "int",
                "_tem": "int"
            },
            assignments: {
                "tem": 'Dvar(Var("_tem"))',
                "hum": 'Dvar(Var("_hum"))'
            },
            rhoPrime: [],
            to: "S1"
        },
        {
            from: "S1",
            guard: [`
            And(
                Not(
                    And(
                        And(
                            LessThanEqual(Dvar(Var("_hum")), Dvar(Var("MaxHum"))),
                            GreaterThanEqual(Dvar(Var("_hum")), Dvar(Var("MinHum")))
                        ),
                        And(
                            LessThanEqual(Dvar(Var("_tem")), Dvar(Var("MaxTem"))),
                            GreaterThanEqual(Dvar(Var("_tem")), Dvar(Var("MinTem")))
                        )
                    )
                ),
                And(
                    GreaterThanEqual(Dvar(Var("_hum")), Val(IntVal(0))),
                    GreaterThanEqual(Dvar(Var("_tem")), Val(IntVal(0)))
                )
            )`, []],
            rho: [],
            ptpVar: "ptpD",
            operation: "ingestTelemetry",
            ptpVarList: [],
            paramVar: {
                "_hum": "int",
                "_tem": "int"
            },
            assignments: {
                "tem": 'Dvar(Var("_tem"))',
                "hum": 'Dvar(Var("_hum"))'
            },
            rhoPrime: [],
            to: "SFail"
        },
        {
            from: "S1",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVar: "ptpO",
            operation: "complete",
            ptpVarList: [],
            paramVar: {},
            assignments: {},
            rhoPrime: [],
            to: "Success"
        }
    ],
    initialState: "_",
    finalStates: ["S1", "SFail", "Success"],
    roles: ["PCP", "CP", "ICP", "SO", "W"],
    variablesList: ["MinHum", "MaxHum", "MinTem", "MaxTem", "hum", "tem"],
    participantsList: {},
    variables: {
        "MinHum": "int",
        "MaxHum": "int",
        "MinTem": "int",
        "MaxTem": "int",
        "hum": "int",
        "tem": "int"
    }
};

export default edam_refrigeratedtransport;

