open Types
open Z3
open Z3_module

(* Define a function to initialize the sigma mapping based on the list of variables *)
let initialize_sigma list_of_vars : sigma_type =
  let sigma = Hashtbl.create (List.length list_of_vars) in
  List.iter (fun (var_type, var_name) ->
    let default_value = match var_type with
      | VarT "int" | VarT "uint" -> IntVal 0
      | VarT "bool" -> BoolVal false
      | VarT "address" | VarT "contract" -> StrVal "0x0000000000000000000000000000000000000000"
      | VarT "string" -> StrVal ""
      | VarT "list_int" -> ListVal []
      | VarT "list_bool" -> ListVal []
      | VarT "list_string" -> ListVal []
      | VarT "map_address_bool" -> MapVal []
      | VarT "map_address_int" -> MapVal []
      | VarT "map_string_int" -> MapVal []
      | VarT "map_string_string" -> MapVal []
      | VarT "map_address_string" -> MapVal []
      | VarT "map_map_address_string_bool" -> MapVal []
      | VarT "map_map_address_string_int" -> MapVal []
      | VarT "map_map_address_address_int" -> MapVal []
      | _ -> match var_type with VarT t -> (StrVal t)
    in
    Hashtbl.add sigma var_name default_value
  ) list_of_vars;
  (fun var ->
    match Hashtbl.find_opt sigma var with
    | Some value -> value
    | None -> failwith ("Variable not found in sigma: " ^ (match var with Var v -> v))
  )





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
let token2_instance = {token1_instance with name = "Token2"}

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
          [(Var "reserveA", Val (IntVal(0))); (Var "reserveB", Val (IntVal(0))); (Var "lpTotalSupply", Val (IntVal(0))); (Var "swapFees", Val (IntVal(0)))],
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
          [(Var "reserveA", Plus(Dvar(Var("reserveA")), Dvar(Var("_amountA")))); (Var "reserveB", Plus(Dvar(Var("reserveB")), Dvar(Var("_amountB")))); (Var "lpTotalSupply", Plus(Dvar(Var("lpTotalSupply")), Plus(Dvar(Var("_amountA")), Dvar(Var("_amountB"))))); (Var "lpBalances", FuncCall ("update_map", [Dvar (Var "lpBalances"); PtID (Ptp "user"); Plus (MapIndex (Dvar (Var "lpBalances"), PtID (Ptp "user"), Val (IntVal 0)), Plus (Dvar (Var "_amountA"), Dvar (Var "_amountB")))]))],
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
          [(Var "reserveA", Plus(Dvar(Var("reserveA")), Dvar(Var("_amountA")))); (Var "reserveB", Plus(Dvar(Var("reserveB")), Dvar(Var("_amountB")))); (Var "lpTotalSupply", Plus (Dvar (Var "lpTotalSupply"), FuncCall ("min", [Divide (Times (Dvar (Var "_amountA"), Dvar (Var "lpTotalSupply")), Dvar (Var "reserveA")); Divide (Times (Dvar (Var "_amountB"), Dvar (Var "lpTotalSupply")), Dvar (Var "reserveB"))]))); (Var "lpBalances", FuncCall ("update_map", [Dvar (Var "lpBalances"); PtID (Ptp "user"); Plus (MapIndex (Dvar (Var "lpBalances"), PtID (Ptp "user"), Val (IntVal 0)), FuncCall ("min", [Divide (Times (Dvar (Var "_amountA"), Dvar (Var "lpTotalSupply")), Dvar (Var "reserveA")); Divide (Times (Dvar (Var "_amountB"), Dvar (Var "lpTotalSupply")), Dvar (Var "reserveB"))]))]))],
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
          [(Var "reserveA", Minus(Dvar(Var("reserveA")), Divide(Times(Dvar(Var("_lpAmount")), Dvar(Var("reserveA"))), Dvar(Var("lpTotalSupply"))))); (Var "reserveB", Minus(Dvar(Var("reserveB")), Divide(Times(Dvar(Var("_lpAmount")), Dvar(Var("reserveB"))), Dvar(Var("lpTotalSupply"))))); (Var "lpTotalSupply", Minus(Dvar(Var("lpTotalSupply")), Dvar(Var("_lpAmount")))); (Var "lpBalances", FuncCall ("update_map", [Dvar (Var "lpBalances"); PtID (Ptp "user"); Minus (MapIndex (Dvar (Var "lpBalances"), PtID (Ptp "user"), Val (IntVal 0)), Dvar (Var "_lpAmount"))]))],
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
          [(Var "_temp", FuncCall("get_amount_out", [Dvar (Var "_amountA"); Dvar (Var "reserveA"); Dvar (Var "reserveB"); Dvar (Var "swapFees")])); (Var "reserveA", Plus(Dvar (Var "reserveA"), Dvar (Var "_amountA"))); (Var "reserveB", Minus (Dvar (Var "reserveB"), Dvar (Var "_temp")))],
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
          [(Var "_temp", FuncCall("get_amount_out", [Dvar (Var "_amountB"); Dvar (Var "reserveB"); Dvar (Var "reserveA"); Dvar (Var "swapFees")])); (Var "reserveA", Minus (Dvar (Var "reserveA"), Dvar (Var "_temp"))); (Var "reserveB", Plus (Dvar (Var "reserveB"), Dvar (Var "_amountB")))],
          (fun p -> match p with | _ -> (fun _ -> Unknown)),
          ""
        ),
        State "S_LiquidityAdded"
      )];
    final_modes = []; 
    initial_state = State "_";
    roles_list = [Role "owner"; Role "liquidity_provider"; Role "swapper"];
    ptp_var_list = [];
    variables_list = [Var "_temp"; Var "reserveA"; Var "reserveB"; Var "lpBalances"; Var "lpTotalSupply"; Var "swapFees"; Var "Token1"; Var "Token2"]
  }

  let list_of_vars = [(VarT "int", Var "_temp"); (VarT "int", Var "reserveA"); (VarT "int", Var "reserveB"); (VarT "map_address_int", Var "lpBalances"); (VarT "int", Var "lpTotalSupply"); (VarT "int", Var "swapFees"); (VarT "Token1Contract", Var "Token1"); (VarT "Token2Contract", Var "Token2")]
  

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




(* Dummy sigma and iota functions *)
let sigma (var : dvar) : value_type =
  match var with
  | Var "x" -> IntVal 5
  | _ -> IntVal 0

let iota (ptp : ptp_var) : participant =
  match ptp with
  | Ptp "P1" -> PID "Alice"
  | _ -> PID "?"



(* Expressions to test *)
let test_expressions = [
    ("PtID", PtID (Ptp "P1"));
    ("ListIndex", ListIndex (Val (ListVal [IntVal 1; IntVal 42]), Val (IntVal 1), Val (IntVal 0)));
    ("MapIndex", MapIndex (Val (MapVal [(StrVal "key1", IntVal 42)]), Val (StrVal "key1"), Val (IntVal 0)));
    ("Map Test", GreaterThanEqual(MapIndex(Dvar(Var("balances")), PtID(Ptp "user"), Val(IntVal(0))), Dvar(Var("_amount"))));
    ("Map Test2", And(GreaterThanEqual(MapIndex(MapIndex(Dvar(Var("allowances")), PtID(Ptp("sender")), Val (MapVal [])), PtID(Ptp "user"), Val(IntVal(0))), Dvar(Var("_amount"))), GreaterThanEqual(MapIndex(Dvar(Var("balances")), PtID(Ptp("sender")), Val(IntVal(0))), Dvar(Var("_amount")))));
    ("FuncCall", FuncCall ("sum",  [Val (ListVal ([IntVal 10; IntVal 10]))]));
    
]


let dvar_list = [(VarT "int", Var "_amountB")]

let () =

  let ctx = Z3.mk_context [] in
  (* Execute and print results *)
  List.iter (fun (desc, guard) ->
    let result, model = check_guard_satisfiability ctx guard dvar_list initial_config_amm.sigma iota configurations in
      (* Printf.printf "%s: %s\n" desc (Z3.Expr.to_string result) *)
    match result with
    | Z3.Solver.SATISFIABLE ->
        Printf.printf "Guard is satisfiable.\n";
        List.iter (fun (var, value) ->
            Printf.printf "%s = %s\n" var (Z3.Expr.to_string value)
          ) model
    | Z3.Solver.UNSATISFIABLE -> Printf.printf "Guard is not satisfiable.\n"
    | Z3.Solver.UNKNOWN -> Printf.printf "Satisfiability unknown.\n"
  ) test_expressions  
