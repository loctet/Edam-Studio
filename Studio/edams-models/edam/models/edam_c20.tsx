import type { EDAMModel } from "../types";

const edam_c20: EDAMModel = {
    name: "C20",
    states: ["q1"],
    transitions: [
        {
            from: "_",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVar: "p",
            operation: "start",
            ptpVarList: [],
            paramVar: {
                "s": "int",
                "b": "string",
                "n": "string",
                "d": "int"
            },
            assignments: {
                "totalSupply": 'Dvar(Var("s"))',
                "symbol": 'Dvar(Var("b"))',
                "name": 'Dvar(Var("n"))',
                "decimals": 'Dvar(Var("d"))',
                "balanceOf": `FuncCall("update_map", [
                    Dvar(Var("balanceOf"));
                    PtID(Ptp("p"));
                    Dvar(Var("s"))
                ])`
            },
            rhoPrime: [
                { user: "p", role: "O", mode: "Top" }
            ],
            to: "q1"
        },
        {
            from: "q1",
            guard: ['GreaterThanEqual(Dvar(Var("a")), Val(IntVal(0)))', []],
            rho: [
                { user: "p", role: "O", mode: "Top" }
            ],
            ptpVar: "p",
            operation: "mint",
            ptpVarList: ["r"],
            paramVar: {
                "a": "int"
            },
            assignments: {
                "totalSupply": 'Plus(Dvar(Var("totalSupply")), Dvar(Var("a")))',
                "balanceOf": `FuncCall("update_map", [
                    Dvar(Var("balanceOf"));
                    PtID(Ptp("r"));
                    Plus(
                        MapIndex(Dvar(Var("balanceOf")), PtID(Ptp("r")), Val(IntVal(0))), 
                        Dvar(Var("a"))
                    )
                ])`
            },
            rhoPrime: [],
            to: "q1"
        },
        {
            from: "q1",
            guard: ['GreaterThanEqual(MapIndex(Dvar(Var("balanceOf")), PtID(Ptp("p")), Val(IntVal(0))), Dvar(Var("a")))', []],
            rho: [],
            ptpVar: "p",
            operation: "transfer",
            ptpVarList: ["r"],
            paramVar: {
                "a": "int"
            },
            assignments: {
                "balanceOf": `FuncCall("update_map", [
                    FuncCall("update_map", [
                        Dvar(Var("balanceOf")); 
                        PtID(Ptp("p")); 
                        Minus(MapIndex(Dvar(Var("balanceOf")), PtID(Ptp("p")), Val(IntVal(0))), Dvar(Var("a")))
                    ]);
                    PtID(Ptp("r"));
                    Plus(MapIndex(
                        FuncCall("update_map", [
                            Dvar(Var("balanceOf")); 
                            PtID(Ptp("p")); 
                            Minus(MapIndex(Dvar(Var("balanceOf")), PtID(Ptp("p")), Val(IntVal(0))), Dvar(Var("a")))
                        ]), 
                        PtID(Ptp("r")),
                        Val(IntVal(0))
                    ), Dvar(Var("a")))
                ])`
            },
            rhoPrime: [],
            to: "q1"
        },
        {
            from: "q1",
            guard: ['Val (BoolVal(true))', []],
            rho: [],
            ptpVar: "p",
            operation: "approve",
            ptpVarList: ["s"],
            paramVar: {
                "a": "int"
            },
            assignments: {
                "allowance": `FuncCall("update_nested_map", [
                    Dvar(Var("allowance"));
                    PtID(Ptp("p"));
                    PtID(Ptp("s"));
                    Dvar(Var("a"))
                ])`
            },
            rhoPrime: [],
            to: "q1"
        },
        {
            from: "q1",
            guard: [`And(
                GreaterThanEqual(
                    MapIndex(
                        MapIndex(
                            Dvar(Var("allowance")), 
                            PtID(Ptp("s")), Val(MapVal([]))
                        ), 
                        PtID(Ptp("p")), 
                        Val(IntVal(0))
                    ), Dvar(Var("a"))
                ),
                GreaterThanEqual(
                    MapIndex(Dvar(Var("balanceOf")), PtID(Ptp("s")), Val(IntVal(0))), 
                    Dvar(Var("a"))
                ) 
            )`, []],
            rho: [],
            ptpVar: "p",
            operation: "transferFrom",
            ptpVarList: ["s", "r"],
            paramVar: {
                "a": "int"
            },
            assignments: {
                "balanceOf": `FuncCall("update_map", [
                    FuncCall("update_map", [
                        Dvar(Var("balanceOf")); 
                        PtID(Ptp("s")); 
                        Minus(MapIndex(Dvar(Var("balanceOf")), PtID(Ptp("s")), Val(IntVal(0))), Dvar(Var("a")))
                    ]);
                    PtID(Ptp("r"));
                    Plus(MapIndex(
                        FuncCall("update_map", [
                            Dvar(Var("balanceOf")); 
                            PtID(Ptp("s")); 
                            Minus(MapIndex(Dvar(Var("balanceOf")), PtID(Ptp("s")), Val(IntVal(0))), Dvar(Var("a")))
                        ]), 
                        PtID(Ptp("r")), Val(IntVal(0))
                    ), Dvar(Var("a")))
                ])`,
                "allowance": `FuncCall("update_nested_map", [
                    Dvar(Var("allowance")); 
                    PtID(Ptp("s")); 
                    PtID(Ptp("p")); 
                    Minus(MapIndex(MapIndex(Dvar(Var("allowance")), PtID(Ptp("s")), Val(MapVal([]))), PtID(Ptp("p")), Val(IntVal(0))), Dvar(Var("a")))
                ])`
            },
            rhoPrime: [],
            to: "q1"
        },
        {
            from: "q1",
            guard: ['GreaterThanEqual(MapIndex(Dvar(Var("balanceOf")), PtID(Ptp("p")), Val(IntVal(0))), Dvar(Var("a")))', []],
            rho: [],
            ptpVar: "p",
            operation: "burn",
            ptpVarList: [],
            paramVar: {
                "a": "int"
            },
            assignments: {
                "totalSupply": 'Minus(Dvar(Var("totalSupply")), Dvar(Var("a")))',
                "balanceOf": `FuncCall("update_map", [
                    Dvar(Var("balanceOf"));
                    PtID(Ptp("p"));
                    Minus(MapIndex(Dvar(Var("balanceOf")), PtID(Ptp("p")), Val(IntVal(0))), Dvar(Var("a")))
                ])`
            },
            rhoPrime: [],
            to: "q1"
        }
    ],
    initialState: "_",
    finalStates: [],
    roles: ["O"],
    variablesList: ["totalSupply", "balanceOf", "allowance"],
    participantsList: {},
    variables: {
        "totalSupply": "int",
        "symbol": "string",
        "name": "string",
        "decimals": "int",
        "balanceOf": "map_address_int",
        "allowance": "map_map_address_address_int"
    }
};

export default edam_c20;


