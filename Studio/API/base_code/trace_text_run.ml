open Str
open Types
open Helper
open Core_functions
open Test_generation




(* Define the multi_config structure *)
let configurations : multi_config = {
  edam_map = Hashtbl.create 3;
  config_map = Hashtbl.create 3;
}


(* Define the EDAM (including name and roles list) *)
let token1_instance = 
  {
    name = "Token1";
    states = [State "S_Deployed"];
    transitions = [(
        State "_",
        (
          (Val (BoolVal(true)), []),
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          Ptp "owner",
          Operation "start",
          [],
          [(VarT "int", Var "initialSupply")],
          [(Var "totalSupply", Dvar(Var("initialSupply"))); (Var "balances", FuncCall ("update_map", [
                        Dvar (Var "balances");
                        PtID (Ptp "owner");
                        Dvar (Var "initialSupply")
                    ]))],
          (fun p -> match p with | Ptp "owner" -> (fun  r -> if r = Role "owner" then Top else Unknown) | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_Deployed"
      ); (
        State "S_Deployed",
        (
          (GreaterThanEqual(Dvar(Var("_amount")), Val(IntVal(0))), []),
          (fun p -> match p with | Ptp "owner" -> (fun  r -> if r = Role "owner" then Top else Unknown) | _ -> (fun _ -> Unknown)),
          Ptp "owner",
          Operation "mint",
          [Ptp "receiver"],
          [(VarT "int", Var "_amount")],
          [(Var "totalSupply", Plus(Dvar(Var("totalSupply")), Dvar(Var("_amount")))); (Var "balances", FuncCall ("update_map", [
                            Dvar (Var "balances");
                            PtID (Ptp "receiver");
                            Plus (
                            MapIndex (Dvar (Var "balances"), PtID (Ptp "receiver"), Val (IntVal 0)), 
                            Dvar (Var "_amount")
                            )
                        ]))],
          (fun p -> match p with | Ptp "receiver" -> (fun  r -> if r = Role "user" then Top else Unknown) | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_Deployed"
      ); (
        State "S_Deployed",
        (
          (GreaterThanEqual(MapIndex(Dvar(Var("balances")), PtID(Ptp "user"), Val(IntVal(0))), Dvar(Var("_amount"))), []),
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          Ptp "user",
          Operation "transfer",
          [Ptp "recipient"],
          [(VarT "int", Var "_amount")],
          [(Var "balances", FuncCall ("update_map", [
                        FuncCall ("update_map", [
                            Dvar (Var "balances"); 
                            PtID (Ptp "user"); 
                            Minus (MapIndex (Dvar (Var "balances"), PtID (Ptp "user"), Val (IntVal 0)), Dvar (Var "_amount"))
                        ]);
                        PtID (Ptp "recipient");
                        Plus (MapIndex (
                        FuncCall ("update_map", [
                            Dvar (Var "balances"); 
                            PtID (Ptp "user"); 
                            Minus (MapIndex (Dvar (Var "balances"), PtID (Ptp "user"), Val (IntVal 0)), Dvar (Var "_amount"))
                        ]), 
                        PtID (Ptp "recipient"),
                        Val (IntVal 0)
                        ), Dvar (Var "_amount"))
                    ]))],
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_Deployed"
      ); (
        State "S_Deployed",
        (
          (Val (BoolVal(true)), []),
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          Ptp "user",
          Operation "approve",
          [Ptp "spender"],
          [(VarT "int", Var "_amount")],
          [(Var "allowances", FuncCall ("update_nested_map", [
                        Dvar (Var "allowances");
                        PtID (Ptp "user");
                        PtID (Ptp "spender");
                        Dvar (Var "_amount")
                    ]))],
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_Deployed"
      ); (
        State "S_Deployed",
        (
          (And (
                    GreaterThanEqual (
                        MapIndex (
                            MapIndex (
                                Dvar (Var "allowances"), 
                                PtID (Ptp "sender"), Val (MapVal [])
                            ), 
                            PtID (Ptp "user"), 
                            Val (IntVal 0)
                        ), Dvar (Var "_amount")
                    ),
                    GreaterThanEqual (
                        MapIndex (Dvar (Var "balances"), PtID (Ptp "sender"), Val (IntVal 0)), 
                        Dvar (Var "_amount")
                    ) 
                ), []),
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          Ptp "user",
          Operation "transferFrom",
          [Ptp "sender"; Ptp "recipient"],
          [(VarT "int", Var "_amount")],
          [(Var "balances", FuncCall ("update_map", [
                        FuncCall ("update_map", [
                            Dvar (Var "balances"); 
                            PtID (Ptp "sender"); 
                            Minus (MapIndex (Dvar (Var "balances"), PtID (Ptp "sender"), Val (IntVal 0)), Dvar (Var "_amount"))
                        ]);
                        PtID (Ptp "recipient");
                        Plus (MapIndex (
                        FuncCall ("update_map", [
                            Dvar (Var "balances"); 
                            PtID (Ptp "sender"); 
                            Minus (MapIndex (Dvar (Var "balances"), PtID (Ptp "sender"), Val (IntVal 0)), Dvar (Var "_amount"))
                        ]), 
                        PtID (Ptp "recipient"), Val (IntVal 0)
                        ), Dvar (Var "_amount"))
                    ])); (Var "allowances", FuncCall ("update_nested_map", [
                        Dvar (Var "allowances"); 
                        PtID (Ptp "sender"); 
                        PtID (Ptp "user"); 
                        Minus (MapIndex (MapIndex (Dvar (Var "allowances"), PtID (Ptp "sender"), Val (MapVal [])), PtID (Ptp "user"), Val (IntVal 0)), Dvar (Var "_amount"))
                    ]))],
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_Deployed"
      ); (
        State "S_Deployed",
        (
          (GreaterThanEqual(MapIndex(Dvar(Var("balances")), PtID(Ptp "user"), Val(IntVal(0))), Dvar(Var("_amount"))), []),
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          Ptp "user",
          Operation "burn",
          [],
          [(VarT "int", Var "_amount")],
          [(Var "totalSupply", Minus(Dvar(Var("totalSupply")), Dvar(Var("_amount")))); (Var "balances", FuncCall ("update_map", [
                        Dvar (Var "balances");
                        PtID (Ptp "user");
                        Minus (MapIndex (Dvar (Var "balances"), PtID (Ptp "user"), Val (IntVal 0)), Dvar (Var "_amount"))
                    ]))],
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_Deployed"
      )];
    final_modes = []; 
    initial_state = State "_";
    roles_list = [Role "owner"; Role "user"];
    ptp_var_list = [];
    variables_list = [Var "totalSupply"; Var "balances"; Var "allowances"]
  }

  let list_of_vars = [(VarT "int", Var "totalSupply"); (VarT "map_address_int", Var "balances"); (VarT "map_map_address_address_int", Var "allowances")]
  

let pi_token1 = fun _ -> []
(* Define the initial EDAM configuration *)
let initial_config_token1 = {
  state = State "_";
  pi = pi_token1;
  sigma = initialize_sigma list_of_vars;
}

(* Add to the multi_config *)
let () =
  Hashtbl.add configurations.edam_map token1_instance.name token1_instance;
  Hashtbl.add configurations.config_map token1_instance.name initial_config_token1



(* Define the EDAM (including name and roles list) *)
let token2_instance = 
  {
    name = "Token2";
    states = [State "S_Deployed"];
    transitions = [(
        State "_",
        (
          (Val (BoolVal(true)), []),
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          Ptp "owner",
          Operation "start",
          [],
          [(VarT "int", Var "initialSupply")],
          [(Var "totalSupply", Dvar(Var("initialSupply"))); (Var "balances", FuncCall ("update_map", [
                        Dvar (Var "balances");
                        PtID (Ptp "owner");
                        Dvar (Var "initialSupply")
                    ]))],
          (fun p -> match p with | Ptp "owner" -> (fun  r -> if r = Role "owner" then Top else Unknown) | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_Deployed"
      ); (
        State "S_Deployed",
        (
          (GreaterThanEqual(Dvar(Var("_amount")), Val(IntVal(0))), []),
          (fun p -> match p with | Ptp "owner" -> (fun  r -> if r = Role "owner" then Top else Unknown) | _ -> (fun _ -> Unknown)),
          Ptp "owner",
          Operation "mint",
          [Ptp "receiver"],
          [(VarT "int", Var "_amount")],
          [(Var "totalSupply", Plus(Dvar(Var("totalSupply")), Dvar(Var("_amount")))); (Var "balances", FuncCall ("update_map", [
                            Dvar (Var "balances");
                            PtID (Ptp "receiver");
                            Plus (
                            MapIndex (Dvar (Var "balances"), PtID (Ptp "receiver"), Val (IntVal 0)), 
                            Dvar (Var "_amount")
                            )
                        ]))],
          (fun p -> match p with | Ptp "receiver" -> (fun  r -> if r = Role "user" then Top else Unknown) | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_Deployed"
      ); (
        State "S_Deployed",
        (
          (GreaterThanEqual(MapIndex(Dvar(Var("balances")), PtID(Ptp "user"), Val(IntVal(0))), Dvar(Var("_amount"))), []),
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          Ptp "user",
          Operation "transfer",
          [Ptp "recipient"],
          [(VarT "int", Var "_amount")],
          [(Var "balances", FuncCall ("update_map", [
                        FuncCall ("update_map", [
                            Dvar (Var "balances"); 
                            PtID (Ptp "user"); 
                            Minus (MapIndex (Dvar (Var "balances"), PtID (Ptp "user"), Val (IntVal 0)), Dvar (Var "_amount"))
                        ]);
                        PtID (Ptp "recipient");
                        Plus (MapIndex (
                        FuncCall ("update_map", [
                            Dvar (Var "balances"); 
                            PtID (Ptp "user"); 
                            Minus (MapIndex (Dvar (Var "balances"), PtID (Ptp "user"), Val (IntVal 0)), Dvar (Var "_amount"))
                        ]), 
                        PtID (Ptp "recipient"),
                        Val (IntVal 0)
                        ), Dvar (Var "_amount"))
                    ]))],
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_Deployed"
      ); (
        State "S_Deployed",
        (
          (Val (BoolVal(true)), []),
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          Ptp "user",
          Operation "approve",
          [Ptp "spender"],
          [(VarT "int", Var "_amount")],
          [(Var "allowances", FuncCall ("update_nested_map", [
                        Dvar (Var "allowances");
                        PtID (Ptp "user");
                        PtID (Ptp "spender");
                        Dvar (Var "_amount")
                    ]))],
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_Deployed"
      ); (
        State "S_Deployed",
        (
          (And (
                    GreaterThanEqual (
                        MapIndex (
                            MapIndex (
                                Dvar (Var "allowances"), 
                                PtID (Ptp "sender"), Val (MapVal [])
                            ), 
                            PtID (Ptp "user"), 
                            Val (IntVal 0)
                        ), Dvar (Var "_amount")
                    ),
                    GreaterThanEqual (
                        MapIndex (Dvar (Var "balances"), PtID (Ptp "sender"), Val (IntVal 0)), 
                        Dvar (Var "_amount")
                    ) 
                ), []),
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          Ptp "user",
          Operation "transferFrom",
          [Ptp "sender"; Ptp "recipient"],
          [(VarT "int", Var "_amount")],
          [(Var "balances", FuncCall ("update_map", [
                        FuncCall ("update_map", [
                            Dvar (Var "balances"); 
                            PtID (Ptp "sender"); 
                            Minus (MapIndex (Dvar (Var "balances"), PtID (Ptp "sender"), Val (IntVal 0)), Dvar (Var "_amount"))
                        ]);
                        PtID (Ptp "recipient");
                        Plus (MapIndex (
                        FuncCall ("update_map", [
                            Dvar (Var "balances"); 
                            PtID (Ptp "sender"); 
                            Minus (MapIndex (Dvar (Var "balances"), PtID (Ptp "sender"), Val (IntVal 0)), Dvar (Var "_amount"))
                        ]), 
                        PtID (Ptp "recipient"), Val (IntVal 0)
                        ), Dvar (Var "_amount"))
                    ])); (Var "allowances", FuncCall ("update_nested_map", [
                        Dvar (Var "allowances"); 
                        PtID (Ptp "sender"); 
                        PtID (Ptp "user"); 
                        Minus (MapIndex (MapIndex (Dvar (Var "allowances"), PtID (Ptp "sender"), Val (MapVal [])), PtID (Ptp "user"), Val (IntVal 0)), Dvar (Var "_amount"))
                    ]))],
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_Deployed"
      ); (
        State "S_Deployed",
        (
          (GreaterThanEqual(MapIndex(Dvar(Var("balances")), PtID(Ptp "user"), Val(IntVal(0))), Dvar(Var("_amount"))), []),
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          Ptp "user",
          Operation "burn",
          [],
          [(VarT "int", Var "_amount")],
          [(Var "totalSupply", Minus(Dvar(Var("totalSupply")), Dvar(Var("_amount")))); (Var "balances", FuncCall ("update_map", [
                        Dvar (Var "balances");
                        PtID (Ptp "user");
                        Minus (MapIndex (Dvar (Var "balances"), PtID (Ptp "user"), Val (IntVal 0)), Dvar (Var "_amount"))
                    ]))],
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_Deployed"
      )];
    final_modes = []; 
    initial_state = State "_";
    roles_list = [Role "owner"; Role "user"];
    ptp_var_list = [];
    variables_list = [Var "totalSupply"; Var "balances"; Var "allowances"]
  }

  let list_of_vars = [(VarT "int", Var "totalSupply"); (VarT "map_address_int", Var "balances"); (VarT "map_map_address_address_int", Var "allowances")]
  

let pi_token2 = fun _ -> []
(* Define the initial EDAM configuration *)
let initial_config_token2 = {
  state = State "_";
  pi = pi_token2;
  sigma = initialize_sigma list_of_vars;
}

(* Add to the multi_config *)
let () =
  Hashtbl.add configurations.edam_map token2_instance.name token2_instance;
  Hashtbl.add configurations.config_map token2_instance.name initial_config_token2



(* Define the EDAM (including name and roles list) *)
let amm_instance = 
  {
    name = "AMM";
    states = [State "S_Deployed"; State "S_LiquidityAdded"; State "S_LiquidityRemoved"; State "S2"];
    transitions = [(
        State "_",
        (
          (Val (BoolVal(true)), []),
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          Ptp "owner",
          Operation "start",
          [],
          [],
          [(Var "reserveA", Val (IntVal(0))); (Var "reserveB", Val (IntVal(0))); (Var "reserveA_", Val (IntVal(0))); (Var "reserveB_", Val (IntVal(0))); (Var "lpTotalSupply", Val (IntVal(0))); (Var "swapFees", Val (IntVal(0)))],
          (fun p -> match p with | Ptp "owner" -> (fun  r -> if r = Role "owner" then Top else Unknown) | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_Deployed"
      ); (
        State "S_Deployed",
        (
          (
                    And (
                        GreaterThan (Dvar (Var "_amountA"), Val (IntVal 0)),
                        And (
                            GreaterThan (Dvar (Var "_amountB"), Val (IntVal 0)),
                            And (
                                Equal (Dvar (Var "reserveA"), Val (IntVal 0)),
                                And (
                                    Equal (Dvar (Var "reserveB"), Val (IntVal 0)),
                                    GreaterThan (Plus (Dvar (Var "_amountA"), Dvar (Var "_amountB")), Val (IntVal 0))
                                )   
                            )
                        )
                    )
                , [(FuncCallEdamWrite ("Token1", Operation "transferFrom", 
                                [Dvar (Var "_amountA")], 
                                [PtID (Ptp "user"); PtID (Ptp "AMM")], 
                                [
                                    (Ptp "user", PtID(Ptp "AMM"));
                                    (Ptp "recipient", PtID(Ptp "AMM"));
                                    (Ptp "sender", PtID(Ptp "user"))
                                ]
                            ), true); (FuncCallEdamWrite ("Token2", Operation "transferFrom", 
                                [Dvar (Var "_amountB")], 
                                [PtID (Ptp "user"); PtID (Ptp "AMM")], 
                                [
                                    (Ptp "user", PtID(Ptp "AMM"));
                                    (Ptp "recipient", PtID(Ptp "AMM"));
                                    (Ptp "sender", PtID(Ptp "user"))
                                ]
                            ), true)]),
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          Ptp "user",
          Operation "addLiquidity",
          [],
          [(VarT "int", Var "_amountA"); (VarT "int", Var "_amountB")],
          [
            (Var "reserveA", Plus(Dvar(Var("reserveA_")), Dvar(Var("_amountA")))); 
            (Var "reserveB", Plus(Dvar(Var("reserveB_")), Dvar(Var("_amountB")))); 
            (Var "lpTotalSupply", Plus(Dvar(Var("lpTotalSupply")), Plus(Dvar(Var("_amountA")), Dvar(Var("_amountB"))))); 
            (Var "lpBalances", FuncCall ("update_map", [Dvar (Var "lpBalances"); PtID (Ptp "user"); Plus (MapIndex (Dvar (Var "lpBalances"), PtID (Ptp "user"), Val (IntVal 0)), Plus (Dvar (Var "_amountA"), Dvar (Var "_amountB")))]));
            (Var "reserveA_", Plus(Dvar(Var("reserveA_")), Dvar(Var("_amountA")))); 
            (Var "reserveB_", Plus(Dvar(Var("reserveB_")), Dvar(Var("_amountB")))); 
            
            ],
          (fun p -> match p with | Ptp "user" -> (fun  r -> if r = Role "liquidity_provider" then Top else Unknown) | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_LiquidityAdded"
      ); (
        State "S_LiquidityAdded",
        (
          (And (
                    GreaterThan (Dvar (Var "_amountA"), Val (IntVal 0)),
                    And (
                        GreaterThan (Dvar (Var "_amountB"), Val (IntVal 0)),
                        And (
                            Not (And (Equal (Dvar (Var "reserveA"), Val (IntVal 0)), Equal (Dvar (Var "reserveB"), Val (IntVal 0)))),
                            And (
                                Equal (Times (Dvar (Var "reserveA"), Dvar (Var "_amountB")), Times (Dvar (Var "reserveB"), Dvar (Var "_amountA"))),
                                GreaterThan (Plus (Dvar (Var "_amountA"), Dvar (Var "_amountB")), Val (IntVal 0))
                            )
                        )
                    )
                )       
            , [(FuncCallEdamWrite ("Token1", Operation "transferFrom", 
                    [Dvar (Var "_amountA")], 
                    [PtID (Ptp "user"); PtID (Ptp "AMM")], 
                    [
                        (Ptp "user", PtID(Ptp "AMM"));
                        (Ptp "recipient", PtID(Ptp "AMM"));
                        (Ptp "sender", PtID(Ptp "user"))
                    ]
                ), true); (FuncCallEdamWrite ("Token2", Operation "transferFrom", 
                    [Dvar (Var "_amountB")], 
                    [PtID (Ptp "user"); PtID (Ptp "AMM")], 
                    [
                        (Ptp "user", PtID(Ptp "AMM"));
                        (Ptp "recipient", PtID(Ptp "AMM"));
                        (Ptp "sender", PtID(Ptp "user"))
                    ]
                ), true)]),
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          Ptp "user",
          Operation "addLiquidity",
          [],
          [(VarT "int", Var "_amountA"); (VarT "int", Var "_amountB")],
          [
            (Var "reserveA", Plus(Dvar(Var("reserveA_")), Dvar(Var("_amountA")))); (Var "reserveB", Plus(Dvar(Var("reserveB_")), Dvar(Var("_amountB")))); 
            (Var "lpTotalSupply", Plus (Dvar (Var "lpTotalSupply"), FuncCall ("min", [Divide (Times (Dvar (Var "_amountA"), Dvar (Var "lpTotalSupply")), Dvar (Var "reserveA_")); Divide (Times (Dvar (Var "_amountB"), Dvar (Var "lpTotalSupply")), Dvar (Var "reserveB_"))]))); 
            (Var "lpBalances", FuncCall ("update_map", [Dvar (Var "lpBalances"); PtID (Ptp "user"); Plus (MapIndex (Dvar (Var "lpBalances"), PtID (Ptp "user"), Val (IntVal 0)), FuncCall ("min", [Divide (Times (Dvar (Var "_amountA"), Dvar (Var "lpTotalSupply")), Dvar (Var "reserveA_")); Divide (Times (Dvar (Var "_amountB"), Dvar (Var "lpTotalSupply")), Dvar (Var "reserveB_"))]))]));
            (Var "reserveA_", Plus(Dvar(Var("reserveA_")), Dvar(Var("_amountA")))); (Var "reserveB_", Plus(Dvar(Var("reserveB_")), Dvar(Var("_amountB")))); 
          ],
          (fun p -> match p with | Ptp "user" -> (fun  r -> if r = Role "liquidity_provider" then Top else Unknown) | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_LiquidityAdded"
      ); (
        State "S_LiquidityAdded",
        (
          (
                And (
                    GreaterThan (Dvar (Var "_lpAmount"), Val (IntVal 0)),
                    GreaterThanEqual (
                        MapIndex (Dvar (Var "lpBalances"), PtID (Ptp "user"), Val (IntVal 0)),
                        Dvar (Var "_lpAmount")
                    )
                )
            , [(FuncCallEdamWrite ("Token2", Operation "transfer", 
                        [Divide (Times (Dvar (Var "_lpAmount"), Dvar (Var "reserveB")), Dvar (Var "lpTotalSupply"))], 
                        [PtID (Ptp "user")], 
                        [
                            (Ptp "user", PtID(Ptp "AMM"));
                            (Ptp "recipient", PtID(Ptp "user"));
                        ]
                    ), true); (FuncCallEdamWrite ("Token1", Operation "transfer", 
                        [Divide (Times (Dvar (Var "_lpAmount"), Dvar (Var "reserveA")), Dvar (Var "lpTotalSupply"))], 
                        [PtID (Ptp "user")], 
                        [
                            (Ptp "user", PtID(Ptp "AMM"));
                            (Ptp "recipient", PtID(Ptp "user"));
                        ]
                    ), true)]),
          (fun p -> match p with | Ptp "user" -> (fun  r -> if r = Role "liquidity_provider" then Top else Unknown) | _ -> (fun _ -> Unknown)),
          Ptp "user",
          Operation "removeLiquidity",
          [],
          [(VarT "int", Var "_lpAmount")],
          [(Var "reserveA", Minus(Dvar(Var("reserveA")), Divide(Times(Dvar(Var("_lpAmount")), Dvar(Var("reserveA"))), Dvar(Var("lpTotalSupply"))))); 
           (Var "reserveB", Minus(Dvar(Var("reserveB")), Divide(Times(Dvar(Var("_lpAmount")), Dvar(Var("reserveB"))), Dvar(Var("lpTotalSupply"))))); 
           (Var "lpTotalSupply", Minus(Dvar(Var("lpTotalSupply")), Dvar(Var("_lpAmount")))); 
           (Var "lpBalances", FuncCall ("update_map", [Dvar (Var "lpBalances"); PtID (Ptp "user"); Minus (MapIndex (Dvar (Var "lpBalances"), PtID (Ptp "user"), Val (IntVal 0)), Dvar (Var "_lpAmount"))]));
           (Var "reserveA_", Minus(Dvar(Var("reserveA")), Divide(Times(Dvar(Var("_lpAmount")), Dvar(Var("reserveA"))), Dvar(Var("lpTotalSupply"))))); 
           (Var "reserveB_", Minus(Dvar(Var("reserveB")), Divide(Times(Dvar(Var("_lpAmount")), Dvar(Var("reserveB"))), Dvar(Var("lpTotalSupply"))))); 
           ],
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_LiquidityAdded"
      ); (
        State "S_LiquidityAdded",
        (
          (
                GreaterThan(
                    Times(Dvar (Var "reserveA"), Dvar (Var "reserveB")),
                    Val (IntVal 0)
                )
            , [(FuncCallEdamWrite ("Token1", Operation "transferFrom", 
                        [Dvar (Var "_amountA")], 
                        [PtID (Ptp "user"); PtID (Ptp "AMM")], 
                        [
                            (Ptp "user", PtID(Ptp "AMM"));
                            (Ptp "recipient", PtID(Ptp "AMM"));
                            (Ptp "sender", PtID(Ptp "user"))
                        ]
                    ), true); (FuncCallEdamWrite ("Token2", Operation "transfer", 
                        [FuncCall("get_amount_out", [Dvar (Var "_amountA"); Dvar (Var "reserveA"); Dvar (Var "reserveB"); Dvar (Var "swapFees")])], 
                        [PtID (Ptp "user")], 
                        [
                            (Ptp "user", PtID(Ptp "AMM"));
                            (Ptp "recipient", PtID(Ptp "user"));
                        ]
                    ), true)]),
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          Ptp "user",
          Operation "swapAForB",
          [],
          [(VarT "int", Var "_amountA")],
          [
            (Var "reserveA", Plus(Dvar (Var "reserveA_"), Dvar (Var "_amountA"))); 
            (Var "reserveB", Minus (Dvar (Var "reserveB_"), FuncCall("get_amount_out", [Dvar (Var "_amountA"); Dvar (Var "reserveA_"); Dvar (Var "reserveB_"); Dvar (Var "swapFees")])));
            (Var "reserveA_", Plus(Dvar (Var "reserveA_"), Dvar (Var "_amountA"))); 
            (Var "reserveB_", Minus (Dvar (Var "reserveB_"), FuncCall("get_amount_out", [Dvar (Var "_amountA"); Dvar (Var "reserveA_"); Dvar (Var "reserveB_"); Dvar (Var "swapFees")])));
          ],
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_LiquidityAdded"
      ); (
        State "S_LiquidityAdded",
        (
          (
                    GreaterThan(
                        Times(Dvar (Var "reserveA"), Dvar (Var "reserveB")),
                        Val (IntVal 0)
                    )
                , [(FuncCallEdamWrite ("Token2", Operation "transferFrom", 
                        [Dvar (Var "_amountB")], 
                        [PtID (Ptp "user"); PtID (Ptp "AMM")], 
                        [
                        (Ptp "user", PtID(Ptp "AMM"));
                        (Ptp "recipient", PtID(Ptp "AMM"));
                        (Ptp "sender", PtID(Ptp "user"))
                        ]
                    ), true); (
                    FuncCallEdamWrite ("Token1", Operation "transfer", 
                        [FuncCall("get_amount_out", [Dvar (Var "_amountB"); Dvar (Var "reserveB"); Dvar (Var "reserveA"); Dvar (Var "swapFees")])], 
                        [PtID (Ptp "user")], 
                        [
                            (Ptp "user", PtID(Ptp "AMM"));
                            (Ptp "recipient", PtID(Ptp "user"));
                        ]
                    ), true)]),
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          Ptp "user",
          Operation "swapBForA",
          [],
          [(VarT "int", Var "_amountB")],
          [
            (Var "reserveA", Minus (Dvar (Var "reserveA_"), FuncCall("get_amount_out", [Dvar (Var "_amountB"); Dvar (Var "reserveB_"); Dvar (Var "reserveA_"); Dvar (Var "swapFees")]))); 
            (Var "reserveB", Plus (Dvar (Var "reserveB_"), Dvar (Var "_amountB")));
            (Var "reserveA_", Minus (Dvar (Var "reserveA_"), FuncCall("get_amount_out", [Dvar (Var "_amountB"); Dvar (Var "reserveB_"); Dvar (Var "reserveA_"); Dvar (Var "swapFees")]))); 
            (Var "reserveB_", Plus (Dvar (Var "reserveB_"), Dvar (Var "_amountB")));
          ],
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_LiquidityAdded"
      )];
    final_modes = []; 
    initial_state = State "_";
    roles_list = [Role "owner"; Role "liquidity_provider"; Role "swapper"];
    ptp_var_list = [];
    variables_list = [Var "_temp"; Var "reserveA"; Var "reserveB"; Var "reserveA_"; Var "reserveB_"; Var "lpBalances"; Var "lpTotalSupply"; Var "swapFees"; Var "Token1"; Var "Token2"]
  }

  let list_of_vars = [(VarT "int", Var "_temp"); (VarT "int", Var "reserveA"); (VarT "int", Var "reserveB"); (VarT "int", Var "reserveA_"); (VarT "int", Var "reserveB_"); (VarT "map_address_int", Var "lpBalances"); (VarT "int", Var "lpTotalSupply"); (VarT "int", Var "swapFees"); (VarT "Token1Contract", Var "Token1"); (VarT "Token2Contract", Var "Token2")]
  

let pi_amm = fun _ -> []
(* Define the initial EDAM configuration *)
let initial_config_amm = {
  state = State "_";
  pi = pi_amm;
  sigma = initialize_sigma list_of_vars;
}

(* Add to the multi_config *)
let () =
  Hashtbl.add configurations.edam_map amm_instance.name amm_instance;
  Hashtbl.add configurations.config_map amm_instance.name initial_config_amm




(* Define the dependencies map for all EDAMs *)
let dependencies_map : dependencies_map = 
  let tbl = Hashtbl.create 3 in
(* Define the dependency for token1 *)
  let dependency_token1 = {
    required_calls = [];
    participant_roles = [];
    can_generate_participants = [];
    can_generate_participants_vars = [];
    transition_probabilities = Hashtbl.create 10;
  } in
  Hashtbl.add tbl token1_instance.name dependency_token1;


  (* Define the dependency for token2 *)
  let dependency_token2 = {
    required_calls = [];
    participant_roles = [];
    can_generate_participants = [];
    can_generate_participants_vars = [];
    transition_probabilities = Hashtbl.create 10;
  } in
  Hashtbl.add tbl token2_instance.name dependency_token2;


  (* Define the dependency for amm *)
  let dependency_amm = {
    required_calls = [];
    participant_roles = [];
    can_generate_participants = [];
    can_generate_participants_vars = [];
    transition_probabilities = Hashtbl.create 10;
  } in
  Hashtbl.add tbl amm_instance.name dependency_amm;
  tbl



(* let calls_list = [
  ("Token1", (PID "p1", Operation "start", [], [IntVal 80]), (generate_iota_from_label "Token1" (PID "p1", Operation "start", [], [IntVal 46]) configurations));
  ("Token2", (PID "p1", Operation "start", [], [IntVal 63]), (generate_iota_from_label "Token2" (PID "p1", Operation "start", [], [IntVal 90]) configurations));
  ("AMM", (PID "p1", Operation "start", [], []), (generate_iota_from_label "AMM" (PID "p1", Operation "start", [], []) configurations));

  (* ("Token1", (PID "p1", Operation "mint", [PID "p1"], [IntVal 20]), (generate_iota_from_label "Token1" (PID "p1", Operation "mint", [PID "p1"], [IntVal 20]) configurations));
  ("Token1", (PID "p1", Operation "mint", [PID "AMM"], [IntVal 20]), (generate_iota_from_label "Token1" (PID "p1", Operation "mint", [PID "AMM"], [IntVal 20]) configurations));
   *)
   ("Token1", (PID "p1", Operation "approve", [PID "AMM"], [IntVal 59]), (generate_iota_from_label "Token1" (PID "p1", Operation "approve", [PID "AMM"], [IntVal 20]) configurations));
  ("Token2", (PID "p1", Operation "approve", [PID "AMM"], [IntVal 97]), (generate_iota_from_label "Token2" (PID "p1", Operation "approve", [PID "AMM"], [IntVal 10]) configurations));
  ("AMM", (PID "p1", Operation "addLiquidity", [], [IntVal 47; IntVal 38]), (generate_iota_from_label "AMM" (PID "p1", Operation "addLiquidity", [], [IntVal 10; IntVal 10]) configurations));
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 85]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 10]) configurations))
  (* ("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 5]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 10]) configurations))
   *)] *)

let calls_list = [
(* Initial deployments *)
("Token1", (PID "p1", Operation "start", [], [IntVal 90]), (generate_iota_from_label "Token1" (PID "p1", Operation "start", [], [IntVal 90]) configurations));
("Token2", (PID "p1", Operation "start", [], [IntVal 50]), (generate_iota_from_label "Token2" (PID "p1", Operation "start", [], [IntVal 50]) configurations));
("AMM", (PID "p1", Operation "start", [], []), (generate_iota_from_label "AMM" (PID "p1", Operation "start", [], []) configurations));

(* Token1 operations *)
("Token1", (PID "p1", Operation "transferFrom", [PID "Token2"; PID "AMM"], [IntVal 49]), (generate_iota_from_label "Token1" (PID "p1", Operation "transferFrom", [PID "Token2"; PID "AMM"], [IntVal 49]) configurations));
("Token1", (PID "p1", Operation "transferFrom", [PID "AMM"; PID "Token2"], [IntVal 12]), (generate_iota_from_label "Token1" (PID "p1", Operation "transferFrom", [PID "AMM"; PID "Token2"], [IntVal 12]) configurations));
("Token1", (PID "p1", Operation "transferFrom", [PID "AMM"; PID "Token2"], [IntVal 0]), (generate_iota_from_label "Token1" (PID "p1", Operation "transferFrom", [PID "AMM"; PID "Token2"], [IntVal 0]) configurations));

(* Token2 operations *)
("Token2", (PID "p1", Operation "mint", [PID "p1"], [IntVal 20]), (generate_iota_from_label "Token2" (PID "p1", Operation "mint", [PID "p1"], [IntVal 20]) configurations));

(* Token1 operations *)
("Token1", (PID "p1", Operation "approve", [PID "AMM"], [IntVal 64]), (generate_iota_from_label "Token1" (PID "p1", Operation "approve", [PID "AMM"], [IntVal 64]) configurations));

(* AMM operations *)
("AMM", (PID "p1", Operation "addLiquidity", [], [IntVal 74; IntVal 29]), (generate_iota_from_label "AMM" (PID "p1", Operation "addLiquidity", [], [IntVal 74; IntVal 29]) configurations));
("AMM", (PID "p1", Operation "addLiquidity", [], [IntVal 22; IntVal 13]), (generate_iota_from_label "AMM" (PID "p1", Operation "addLiquidity", [], [IntVal 22; IntVal 13]) configurations));
("AMM", (PID "p1", Operation "addLiquidity", [], [IntVal 1; IntVal 1]), (generate_iota_from_label "AMM" (PID "p1", Operation "addLiquidity", [], [IntVal 1; IntVal 1]) configurations));
("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 62]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 62]) configurations));
("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 7]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 7]) configurations));
("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 52]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 52]) configurations));

  (* Token2 operations *)
  ("Token2", (PID "p1", Operation "burn", [], [IntVal 8]), (generate_iota_from_label "Token2" (PID "p1", Operation "burn", [], [IntVal 8]) configurations));
  
  (* AMM operations *)
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 0]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 0]) configurations));
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 45]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 45]) configurations));
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 33]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 33]) configurations));
  
  (* Token2 operations *)
  ("Token2", (PID "p1", Operation "transferFrom", [PID "p1"; PID "Token1"], [IntVal 5]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "p1"; PID "Token1"], [IntVal 5]) configurations));
  ("Token2", (PID "p1", Operation "transferFrom", [PID "AMM"; PID "AMM"], [IntVal 85]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "AMM"; PID "AMM"], [IntVal 85]) configurations));
  ("Token2", (PID "p1", Operation "transferFrom", [PID "Token1"; PID "AMM"], [IntVal 59]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "Token1"; PID "AMM"], [IntVal 59]) configurations));
  ("Token2", (PID "p1", Operation "transferFrom", [PID "AMM"; PID "AMM"], [IntVal 12]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "AMM"; PID "AMM"], [IntVal 12]) configurations));
  ("Token2", (PID "p1", Operation "transferFrom", [PID "Token1"; PID "Token1"], [IntVal 53]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "Token1"; PID "Token1"], [IntVal 53]) configurations));
  ("Token2", (PID "p1", Operation "transferFrom", [PID "AMM"; PID "AMM"], [IntVal 30]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "AMM"; PID "AMM"], [IntVal 30]) configurations));
  
  (* AMM operations *)
  ("AMM", (PID "p1", Operation "addLiquidity", [], [IntVal 19; IntVal 60]), (generate_iota_from_label "AMM" (PID "p1", Operation "addLiquidity", [], [IntVal 19; IntVal 60]) configurations));
  ("AMM", (PID "p1", Operation "addLiquidity", [], [IntVal 70; IntVal 32]), (generate_iota_from_label "AMM" (PID "p1", Operation "addLiquidity", [], [IntVal 70; IntVal 32]) configurations));
  ("AMM", (PID "p1", Operation "addLiquidity", [], [IntVal 19; IntVal 85]), (generate_iota_from_label "AMM" (PID "p1", Operation "addLiquidity", [], [IntVal 19; IntVal 85]) configurations));
  ("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 74]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 74]) configurations));
  ("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 20]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 20]) configurations));
  ("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 8]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 8]) configurations));
  
  (* Token1 operations *)
  ("Token1", (PID "p1", Operation "transfer", [PID "p1"], [IntVal 27]), (generate_iota_from_label "Token1" (PID "p1", Operation "transfer", [PID "p1"], [IntVal 27]) configurations));
  
  (* Token2 operations *)
  ("Token2", (PID "p1", Operation "transferFrom", [PID "p1"; PID "AMM"], [IntVal 37]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "p1"; PID "AMM"], [IntVal 37]) configurations));
  ("Token2", (PID "p1", Operation "transferFrom", [PID "Token1"; PID "AMM"], [IntVal 45]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "Token1"; PID "AMM"], [IntVal 45]) configurations));
  ("Token2", (PID "p1", Operation "transferFrom", [PID "p1"; PID "p1"], [IntVal 93]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "p1"; PID "p1"], [IntVal 93]) configurations));
  
  (* Token1 operations *)
  ("Token1", (PID "p1", Operation "burn", [], [IntVal 88]), (generate_iota_from_label "Token1" (PID "p1", Operation "burn", [], [IntVal 88]) configurations));
  
  (* Token2 operations *)
  ("Token2", (PID "p1", Operation "burn", [], [IntVal 92]), (generate_iota_from_label "Token2" (PID "p1", Operation "burn", [], [IntVal 92]) configurations));
  ("Token2", (PID "p1", Operation "burn", [], [IntVal 65]), (generate_iota_from_label "Token2" (PID "p1", Operation "burn", [], [IntVal 65]) configurations));
  ("Token2", (PID "p1", Operation "burn", [], [IntVal 41]), (generate_iota_from_label "Token2" (PID "p1", Operation "burn", [], [IntVal 41]) configurations));
  ("Token2", (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 31]), (generate_iota_from_label "Token2" (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 31]) configurations));
  ("Token2", (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 21]), (generate_iota_from_label "Token2" (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 21]) configurations));
  ("Token2", (PID "p1", Operation "approve", [PID "Token1"], [IntVal 94]), (generate_iota_from_label "Token2" (PID "p1", Operation "approve", [PID "Token1"], [IntVal 94]) configurations));
  ("Token2", (PID "p1", Operation "mint", [PID "Token1"], [IntVal 75]), (generate_iota_from_label "Token2" (PID "p1", Operation "mint", [PID "Token1"], [IntVal 75]) configurations));
  
  (* AMM operations *)
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 1]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 1]) configurations));
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 57]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 57]) configurations));
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 52]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 52]) configurations));
(* Token2 operations *)
("Token2", (PID "p1", Operation "approve", [PID "AMM"], [IntVal 100]), (generate_iota_from_label "Token2" (PID "p1", Operation "approve", [PID "AMM"], [IntVal 100]) configurations));

(* AMM operations *)
("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 33]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 33]) configurations));
("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 5]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 5]) configurations));
("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 33]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 33]) configurations));

(* Token1 operations *)
("Token1", (PID "p1", Operation "transferFrom", [PID "p1"; PID "Token2"], [IntVal 52]), (generate_iota_from_label "Token1" (PID "p1", Operation "transferFrom", [PID "p1"; PID "Token2"], [IntVal 52]) configurations));
("Token1", (PID "p1", Operation "transferFrom", [PID "AMM"; PID "AMM"], [IntVal 34]), (generate_iota_from_label "Token1" (PID "p1", Operation "transferFrom", [PID "AMM"; PID "AMM"], [IntVal 34]) configurations));
("Token1", (PID "p1", Operation "transferFrom", [PID "p1"; PID "p1"], [IntVal 29]), (generate_iota_from_label "Token1" (PID "p1", Operation "transferFrom", [PID "p1"; PID "p1"], [IntVal 29]) configurations));

(* AMM operations *)
("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 15]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 15]) configurations));
("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 45]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 45]) configurations));
("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 99]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 99]) configurations));
("AMM", (PID "p1", Operation "addLiquidity", [], [IntVal 63; IntVal 70]), (generate_iota_from_label "AMM" (PID "p1", Operation "addLiquidity", [], [IntVal 63; IntVal 70]) configurations));
("AMM", (PID "p1", Operation "addLiquidity", [], [IntVal 18; IntVal 12]), (generate_iota_from_label "AMM" (PID "p1", Operation "addLiquidity", [], [IntVal 18; IntVal 12]) configurations));
("AMM", (PID "p1", Operation "addLiquidity", [], [IntVal 74; IntVal 50]), (generate_iota_from_label "AMM" (PID "p1", Operation "addLiquidity", [], [IntVal 74; IntVal 50]) configurations));
("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 10]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 10]) configurations));
("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 7]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 7]) configurations));
("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 56]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 56]) configurations));
("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 37]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 37]) configurations));
("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 12]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 12]) configurations));
("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 89]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 89]) configurations));

(* Token2 operations *)
("Token2", (PID "p1", Operation "burn", [], [IntVal 19]), (generate_iota_from_label "Token2" (PID "p1", Operation "burn", [], [IntVal 19]) configurations));
("Token2", (PID "p1", Operation "burn", [], [IntVal 63]), (generate_iota_from_label "Token2" (PID "p1", Operation "burn", [], [IntVal 63]) configurations));
("Token2", (PID "p1", Operation "burn", [], [IntVal 75]), (generate_iota_from_label "Token2" (PID "p1", Operation "burn", [], [IntVal 75]) configurations));

(* AMM operations *)
("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 62]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 62]) configurations));
("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 95]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 95]) configurations));
("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 23]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 23]) configurations));

(* Token1 operations *)
("Token1", (PID "p1", Operation "approve", [PID "AMM"], [IntVal 83]), (generate_iota_from_label "Token1" (PID "p1", Operation "approve", [PID "AMM"], [IntVal 83]) configurations));

(* Token2 operations *)
("Token2", (PID "p1", Operation "approve", [PID "AMM"], [IntVal 42]), (generate_iota_from_label "Token2" (PID "p1", Operation "approve", [PID "AMM"], [IntVal 42]) configurations));
("Token2", (PID "p1", Operation "mint", [PID "Token1"], [IntVal 55]), (generate_iota_from_label "Token2" (PID "p1", Operation "mint", [PID "Token1"], [IntVal 55]) configurations));

(* AMM operations *)
("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 91]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 91]) configurations));
("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 28]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 28]) configurations));
("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 11]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 11]) configurations));

(* Token2 operations *)
("Token2", (PID "p1", Operation "transferFrom", [PID "p1"; PID "Token1"], [IntVal 27]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "p1"; PID "Token1"], [IntVal 27]) configurations));
("Token2", (PID "p1", Operation "transferFrom", [PID "Token1"; PID "AMM"], [IntVal 90]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "Token1"; PID "AMM"], [IntVal 90]) configurations));

  (* Token2 operations *)
  ("Token2", (PID "p1", Operation "transferFrom", [PID "Token1"; PID "Token1"], [IntVal 46]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "Token1"; PID "Token1"], [IntVal 46]) configurations));
  
  (* AMM operations *)
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 40]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 40]) configurations));
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 94]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 94]) configurations));
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 91]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 91]) configurations));
  
  (* Token1 operations *)
  ("Token1", (PID "p1", Operation "approve", [PID "p1"], [IntVal 78]), (generate_iota_from_label "Token1" (PID "p1", Operation "approve", [PID "p1"], [IntVal 78]) configurations));
  ("Token1", (PID "p1", Operation "transferFrom", [PID "Token2"; PID "p1"], [IntVal 61]), (generate_iota_from_label "Token1" (PID "p1", Operation "transferFrom", [PID "Token2"; PID "p1"], [IntVal 61]) configurations));
  ("Token1", (PID "p1", Operation "transferFrom", [PID "Token2"; PID "Token2"], [IntVal 47]), (generate_iota_from_label "Token1" (PID "p1", Operation "transferFrom", [PID "Token2"; PID "Token2"], [IntVal 47]) configurations));
  ("Token1", (PID "p1", Operation "transferFrom", [PID "p1"; PID "Token2"], [IntVal 95]), (generate_iota_from_label "Token1" (PID "p1", Operation "transferFrom", [PID "p1"; PID "Token2"], [IntVal 95]) configurations));
  
  (* AMM operations *)
  ("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 14]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 14]) configurations));
  ("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 61]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 61]) configurations));
  ("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 61]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 61]) configurations));
  ("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 43]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 43]) configurations));
  ("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 64]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 64]) configurations));
  ("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 99]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 99]) configurations));
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 96]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 96]) configurations));
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 96]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 96]) configurations));
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 8]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 8]) configurations));
  
  (* Token2 operations *)
  ("Token2", (PID "p1", Operation "approve", [PID "AMM"], [IntVal 23]), (generate_iota_from_label "Token2" (PID "p1", Operation "approve", [PID "AMM"], [IntVal 23]) configurations));
  ("Token2", (PID "p1", Operation "burn", [], [IntVal 33]), (generate_iota_from_label "Token2" (PID "p1", Operation "burn", [], [IntVal 33]) configurations));
  ("Token2", (PID "p1", Operation "burn", [], [IntVal 59]), (generate_iota_from_label "Token2" (PID "p1", Operation "burn", [], [IntVal 59]) configurations));
  ("Token2", (PID "p1", Operation "burn", [], [IntVal 10]), (generate_iota_from_label "Token2" (PID "p1", Operation "burn", [], [IntVal 10]) configurations));
  ("Token2", (PID "p1", Operation "mint", [PID "p1"], [IntVal 75]), (generate_iota_from_label "Token2" (PID "p1", Operation "mint", [PID "p1"], [IntVal 75]) configurations));
  
  (* Token1 operations *)
  ("Token1", (PID "p1", Operation "burn", [], [IntVal 86]), (generate_iota_from_label "Token1" (PID "p1", Operation "burn", [], [IntVal 86]) configurations));
  ("Token1", (PID "p1", Operation "burn", [], [IntVal 45]), (generate_iota_from_label "Token1" (PID "p1", Operation "burn", [], [IntVal 45]) configurations));
  ("Token1", (PID "p1", Operation "burn", [], [IntVal 29]), (generate_iota_from_label "Token1" (PID "p1", Operation "burn", [], [IntVal 29]) configurations));
  
  (* AMM operations *)
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 21]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 21]) configurations));
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 85]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 85]) configurations));
  ("AMM", (PID "p1", Operation "removeLiquidity", [], [IntVal 41]), (generate_iota_from_label "AMM" (PID "p1", Operation "removeLiquidity", [], [IntVal 41]) configurations));
  
  (* Token1 operations *)
  ("Token1", (PID "p1", Operation "transfer", [PID "p1"], [IntVal 47]), (generate_iota_from_label "Token1" (PID "p1", Operation "transfer", [PID "p1"], [IntVal 47]) configurations));
  ("Token1", (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 44]), (generate_iota_from_label "Token1" (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 44]) configurations));
  ("Token1", (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 2]), (generate_iota_from_label "Token1" (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 2]) configurations));
  
  (* AMM operations *)
  ("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 80]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 80]) configurations));
  ("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 75]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 75]) configurations));
  ("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 89]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 89]) configurations));
  ("AMM", (PID "p1", Operation "addLiquidity", [], [IntVal 71; IntVal 32]), (generate_iota_from_label "AMM" (PID "p1", Operation "addLiquidity", [], [IntVal 71; IntVal 32]) configurations));
  ("AMM", (PID "p1", Operation "addLiquidity", [], [IntVal 12; IntVal 80]), (generate_iota_from_label "AMM" (PID "p1", Operation "addLiquidity", [], [IntVal 12; IntVal 80]) configurations));
  ("AMM", (PID "p1", Operation "addLiquidity", [], [IntVal 94; IntVal 37]), (generate_iota_from_label "AMM" (PID "p1", Operation "addLiquidity", [], [IntVal 94; IntVal 37]) configurations));
  
  (* Token1 operations *)
  ("Token1", (PID "p1", Operation "transfer", [PID "Token2"], [IntVal 8]), (generate_iota_from_label "Token1" (PID "p1", Operation "transfer", [PID "Token2"], [IntVal 8]) configurations));
  ("Token1", (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 48]), (generate_iota_from_label "Token1" (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 48]) configurations));
  ("Token1", (PID "p1", Operation "transfer", [PID "Token2"], [IntVal 3]), (generate_iota_from_label "Token1" (PID "p1", Operation "transfer", [PID "Token2"], [IntVal 3]) configurations));
  
  (* Token2 operations *)
  ("Token2", (PID "p1", Operation "approve", [PID "Token1"], [IntVal 85]), (generate_iota_from_label "Token2" (PID "p1", Operation "approve", [PID "Token1"], [IntVal 85]) configurations));
  ("Token2", (PID "p1", Operation "transfer", [PID "Token1"], [IntVal 98]), (generate_iota_from_label "Token2" (PID "p1", Operation "transfer", [PID "Token1"], [IntVal 98]) configurations));
  ("Token2", (PID "p1", Operation "transfer", [PID "Token1"], [IntVal 77]), (generate_iota_from_label "Token2" (PID "p1", Operation "transfer", [PID "Token1"], [IntVal 77]) configurations));
  ("Token2", (PID "p1", Operation "transfer", [PID "p1"], [IntVal 16]), (generate_iota_from_label "Token2" (PID "p1", Operation "transfer", [PID "p1"], [IntVal 16]) configurations));
  ("Token2", (PID "p1", Operation "burn", [], [IntVal 84]), (generate_iota_from_label "Token2" (PID "p1", Operation "burn", [], [IntVal 84]) configurations));
  ("Token2", (PID "p1", Operation "burn", [], [IntVal 53]), (generate_iota_from_label "Token2" (PID "p1", Operation "burn", [], [IntVal 53]) configurations));
  ("Token2", (PID "p1", Operation "burn", [], [IntVal 32]), (generate_iota_from_label "Token2" (PID "p1", Operation "burn", [], [IntVal 32]) configurations));
  ("Token2", (PID "p1", Operation "burn", [], [IntVal 48]), (generate_iota_from_label "Token2" (PID "p1", Operation "burn", [], [IntVal 48]) configurations));
  ("Token2", (PID "p1", Operation "burn", [], [IntVal 97]), (generate_iota_from_label "Token2" (PID "p1", Operation "burn", [], [IntVal 97]) configurations));
  ("Token2", (PID "p1", Operation "transferFrom", [PID "Token1"; PID "Token1"], [IntVal 72]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "Token1"; PID "Token1"], [IntVal 72]) configurations));
  ("Token2", (PID "p1", Operation "transferFrom", [PID "AMM"; PID "AMM"], [IntVal 36]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "AMM"; PID "AMM"], [IntVal 36]) configurations));
  ("Token2", (PID "p1", Operation "transferFrom", [PID "p1"; PID "AMM"], [IntVal 43]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "p1"; PID "AMM"], [IntVal 43]) configurations));
  ("Token2", (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 6]), (generate_iota_from_label "Token2" (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 6]) configurations));
  
  (* Token1 operations *)
  ("Token1", (PID "p1", Operation "mint", [PID "p1"], [IntVal 98]), (generate_iota_from_label "Token1" (PID "p1", Operation "mint", [PID "p1"], [IntVal 98]) configurations));
  
  (* Token2 operations *)
  ("Token2", (PID "p1", Operation "transfer", [PID "Token1"], [IntVal 44]), (generate_iota_from_label "Token2" (PID "p1", Operation "transfer", [PID "Token1"], [IntVal 44]) configurations));
  
    (* Token2 operations *)
    ("Token2", (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 53]), (generate_iota_from_label "Token2" (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 53]) configurations));
    ("Token2", (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 21]), (generate_iota_from_label "Token2" (PID "p1", Operation "transfer", [PID "AMM"], [IntVal 21]) configurations));
    ("Token2", (PID "p1", Operation "mint", [PID "AMM"], [IntVal 35]), (generate_iota_from_label "Token2" (PID "p1", Operation "mint", [PID "AMM"], [IntVal 35]) configurations));
  
    (* Token1 operations *)
    ("Token1", (PID "p1", Operation "transfer", [PID "Token2"], [IntVal 8]), (generate_iota_from_label "Token1" (PID "p1", Operation "transfer", [PID "Token2"], [IntVal 8]) configurations));
  
    (* AMM operations *)
    ("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 46]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 46]) configurations));
    ("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 62]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 62]) configurations));
    ("AMM", (PID "p1", Operation "swapAForB", [], [IntVal 91]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapAForB", [], [IntVal 91]) configurations));
  
    (* Token2 operations *)
    ("Token2", (PID "p1", Operation "approve", [PID "Token1"], [IntVal 47]), (generate_iota_from_label "Token2" (PID "p1", Operation "approve", [PID "Token1"], [IntVal 47]) configurations));
    ("Token2", (PID "p1", Operation "transferFrom", [PID "AMM"; PID "AMM"], [IntVal 25]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "AMM"; PID "AMM"], [IntVal 25]) configurations));
    ("Token2", (PID "p1", Operation "transferFrom", [PID "p1"; PID "Token1"], [IntVal 98]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "p1"; PID "Token1"], [IntVal 98]) configurations));
    ("Token2", (PID "p1", Operation "transferFrom", [PID "Token1"; PID "p1"], [IntVal 73]), (generate_iota_from_label "Token2" (PID "p1", Operation "transferFrom", [PID "Token1"; PID "p1"], [IntVal 73]) configurations));
  
    (* Token1 operations *)
    ("Token1", (PID "p1", Operation "approve", [PID "AMM"], [IntVal 90]), (generate_iota_from_label "Token1" (PID "p1", Operation "approve", [PID "AMM"], [IntVal 90]) configurations));
  
    (* Token2 operations *)
    ("Token2", (PID "p1", Operation "mint", [PID "AMM"], [IntVal 10]), (generate_iota_from_label "Token2" (PID "p1", Operation "mint", [PID "AMM"], [IntVal 10]) configurations));
  
    (* Token1 operations *)
    ("Token1", (PID "p1", Operation "transferFrom", [PID "Token2"; PID "AMM"], [IntVal 67]), (generate_iota_from_label "Token1" (PID "p1", Operation "transferFrom", [PID "Token2"; PID "AMM"], [IntVal 67]) configurations));
    ("Token1", (PID "p1", Operation "transferFrom", [PID "AMM"; PID "p1"], [IntVal 26]), (generate_iota_from_label "Token1" (PID "p1", Operation "transferFrom", [PID "AMM"; PID "p1"], [IntVal 26]) configurations));
    ("Token1", (PID "p1", Operation "transferFrom", [PID "AMM"; PID "p1"], [IntVal 85]), (generate_iota_from_label "Token1" (PID "p1", Operation "transferFrom", [PID "AMM"; PID "p1"], [IntVal 85]) configurations));
  
    (* AMM operations *)
    ("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 27]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 27]) configurations));
    ("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 18]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 18]) configurations));
    ("AMM", (PID "p1", Operation "swapBForA", [], [IntVal 26]), (generate_iota_from_label "AMM" (PID "p1", Operation "swapBForA", [], [IntVal 26]) configurations));
    ("AMM", (PID "p1", Operation "addLiquidity", [], [IntVal 40; IntVal 52]), (generate_iota_from_label "AMM" (PID "p1", Operation "addLiquidity", [], [IntVal 40; IntVal 52]) configurations));
    ("AMM", (PID "p1", Operation "addLiquidity", [], [IntVal 48; IntVal 16]), (generate_iota_from_label "AMM" (PID "p1", Operation "addLiquidity", [], [IntVal 48; IntVal 16]) configurations))
  
]

let () = 
  let (evaluated_trace, conf) = Core_functions.evaluate_trace calls_list configurations in
  Printer.print_trace evaluated_trace;
  Printer.print_all_sigmas conf;

  (* Random.self_init ();

  (* Define the EDAM (including name and roles list) *)
  let server_configs: server_config_type = {
    probability_new_participant = 0.001;
    probability_true_for_bool = 0.5;
    probability_right_participant = 0.9999;
    min_int_value = 10;
    max_int_value = 100;
    max_gen_array_size = 10;
    min_gen_string_length = 5;
    max_gen_string_length = 10;
    z3_check_enabled = true;
    latest_transitions = Hashtbl.create 10;
    executed_operations_log = Hashtbl.create 0;
    max_fail_try = 1;
    add_pi_to_test  = true;
    add_test_of_state  = true;
    add_test_of_variables = true;
  } in 
  print_endline "++++++++++++++++++++++++";
  (* Generate traces *)
  let traces = 
    List.init 1 (fun trace_idx ->
      let multi_cfg_copy = copy_multi_config configurations in
      let new_server_configs = {server_configs with latest_transitions = Hashtbl.create 10; executed_operations_log = Hashtbl.create 0} in
      let (symbolic_trace, generated_trace) = generate_random_trace multi_cfg_copy dependencies_map new_server_configs 1 2 (trace_idx +1) in
      let evaluated_traces = 
        List.map (fun trace -> 
          let evaluated_trace, _ = evaluate_trace (List.rev trace) (copy_multi_config configurations) in
          evaluated_trace
        ) generated_trace 
      in 
      Printer.print_symbolic_trace symbolic_trace (trace_idx + 1);
      print_endline "++++++++++++++++++++++++";
      evaluated_traces
    )
  |> List.concat in

  print_endline "________";

  (* Generate and print migration and test scripts for all traces *)
  let migration_code, test_code = generate_hardhat_tests configurations traces server_configs  in
  print_endline test_code;
  print_endline "________";
  print_endline migration_code; *)
