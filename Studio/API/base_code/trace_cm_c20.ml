open Str
open Types
open Helper
open Core_functions
open Test_generation



(* Define the multi_config structure *)
let configurations : multi_config = {
  edam_map = Hashtbl.create 2;
  config_map = Hashtbl.create 2;
}


(* Define the EDAM (including name and roles list) *)
let c20_instance = 
{
  name = "C20";
  states = [State "q1"];
  transitions = [(
      State "_",
      (
        (Val (BoolVal(true)), []),
        (fun p -> match p with | _ -> (fun _ -> Unknown)),
        Ptp "p",
        Operation "start",
        [],
        [(VarT "int", Var "s"); (VarT "string", Var "b"); (VarT "string", Var "n"); (VarT "int", Var "d")],
        [(Var "totalSupply", Dvar(Var("s"))); 
          (Var "symbol", Dvar(Var("b"))); 
          (Var "name", Dvar(Var("n"))); 
          (Var "decimals", Dvar(Var("d"))); 
          (Var "balanceOf", FuncCall("update_map", [
                    Dvar(Var("balanceOf"));
                    PtID(Ptp("p"));
                    Dvar(Var("s"))
                ]))],
        (fun p -> match p with | Ptp "p" -> (fun  r -> if r = Role "O" then Top else Unknown) | _ -> (fun _ -> Unknown)),
        ""
      ),
      State "q1"
    ); (
      State "q1",
      (
        (GreaterThanEqual(Dvar(Var("a")), Val(IntVal(0))), []),
        (fun p -> match p with | Ptp "p" -> (fun  r -> if r = Role "O" then Top else Unknown) | _ -> (fun _ -> Unknown)),
        Ptp "p",
        Operation "mint",
        [Ptp "r"],
        [(VarT "int", Var "a")],
        [(Var "totalSupply", Plus(Dvar(Var("totalSupply")), Dvar(Var("a")))); 
          (Var "balanceOf", FuncCall("update_map", [
                    Dvar(Var("balanceOf"));
                    PtID(Ptp("r"));
                    Plus(
                        MapIndex(Dvar(Var("balanceOf")), PtID(Ptp("r")), Val(IntVal(0))), 
                        Dvar(Var("a"))
                    )
                ]))],
        (fun p -> match p with | _ -> (fun _ -> Unknown)),
        ""
      ),
      State "q1"
    ); (
      State "q1",
      (
        (GreaterThanEqual(MapIndex(Dvar(Var("balanceOf")), PtID(Ptp("p")), Val(IntVal(0))), Dvar(Var("a"))), []),
        (fun p -> match p with | _ -> (fun _ -> Unknown)),
        Ptp "p",
        Operation "transfer",
        [Ptp "r"],
        [(VarT "int", Var "a")],
        [(Var "balanceOf", FuncCall("update_map", [
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
                ]))],
        (fun p -> match p with | _ -> (fun _ -> Unknown)),
        ""
      ),
      State "q1"
    ); (
      State "q1",
      (
        (Val (BoolVal(true)), []),
        (fun p -> match p with | _ -> (fun _ -> Unknown)),
        Ptp "p",
        Operation "approve",
        [Ptp "s"],
        [(VarT "int", Var "a")],
        [(Var "allowance", FuncCall("update_nested_map", [
                    Dvar(Var("allowance"));
                    PtID(Ptp("p"));
                    PtID(Ptp("s"));
                    Dvar(Var("a"))
                ]))],
        (fun p -> match p with | _ -> (fun _ -> Unknown)),
        ""
      ),
      State "q1"
    ); (
      State "q1",
      (
        (And(
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
            ), []),
        (fun p -> match p with | _ -> (fun _ -> Unknown)),
        Ptp "p",
        Operation "transferFrom",
        [Ptp "s"; Ptp "r"],
        [(VarT "int", Var "a")],
        [(Var "balanceOf", FuncCall("update_map", [
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
                ])); 
                (Var "allowance", FuncCall("update_nested_map", [
                    Dvar(Var("allowance")); 
                    PtID(Ptp("s")); 
                    PtID(Ptp("p")); 
                    Minus(MapIndex(MapIndex(Dvar(Var("allowance")), PtID(Ptp("s")), Val(MapVal([]))), PtID(Ptp("p")), Val(IntVal(0))), Dvar(Var("a")))
                ]))],
        (fun p -> match p with | _ -> (fun _ -> Unknown)),
        ""
      ),
      State "q1"
    ); (
      State "q1",
      (
        (GreaterThanEqual(MapIndex(Dvar(Var("balanceOf")), PtID(Ptp("p")), Val(IntVal(0))), Dvar(Var("a"))), []),
        (fun p -> match p with | _ -> (fun _ -> Unknown)),
        Ptp "p",
        Operation "burn",
        [],
        [(VarT "int", Var "a")],
        [(Var "totalSupply", Minus(Dvar(Var("totalSupply")), Dvar(Var("a")))); 
          (Var "balanceOf", FuncCall("update_map", [
                    Dvar(Var("balanceOf"));
                    PtID(Ptp("p"));
                    Minus(MapIndex(Dvar(Var("balanceOf")), PtID(Ptp("p")), Val(IntVal(0))), Dvar(Var("a")))
                ]))],
        (fun p -> match p with | _ -> (fun _ -> Unknown)),
        ""
      ),
      State "q1"
    )];
  final_modes = []; 
  initial_state = State "_";
  roles_list = [Role "O"];
  ptp_var_list = [];
  variables_list = [Var "totalSupply"; Var "balanceOf"; Var "allowance"]
}

let list_of_vars = [(VarT "int", Var "totalSupply"); (VarT "string", Var "symbol"); (VarT "string", Var "name"); (VarT "int", Var "decimals"); (VarT "map_address_int", Var "balanceOf"); (VarT "map_map_address_address_int", Var "allowance")]


let pi_c20 = fun _ -> []
(* Define the initial EDAM configuration *)
let initial_config_c20 = {
  state = State "_";
  pi = pi_c20;
  sigma = initialize_sigma list_of_vars;
}

(* Add to the multi_config *)
let () =
  Hashtbl.add configurations.edam_map c20_instance.name c20_instance;
  Hashtbl.add configurations.config_map c20_instance.name initial_config_c20



(* Define the EDAM (including name and roles list) *)
let cm_instance = 
{
  name = "Cm";
  states = [State "q1"; State "q2"; State "q3"];
  transitions = [(
      State "_",
      (
        (Val (BoolVal(true)), []),
        (fun p -> match p with | _ -> (fun _ -> Unknown)),
        Ptp "p",
        Operation "start",
        [],
        [(VarT "string", Var "d"); (VarT "int", Var "b")],
        [(Var "des", Dvar(Var("d"))); 
        (Var "pr", Dvar(Var("b")))],
        (fun p -> match p with | Ptp "p" -> (fun  r -> if r = Role "O" then Top else Unknown) | _ -> (fun _ -> Unknown)),
        ""
      ),
      State "q1"
    ); (
      State "q1",
      (
        (GreaterThan(Dvar(Var("a")), Dvar(Var("off"))), [(
          FuncCallEdamWrite(
              "C20", 
              Operation("transferFrom"), 
              [PtID (Ptp "p"); Self("Cm")], 
              [Dvar (Var "a")]
          ), true)]),
        (fun p -> match p with | _ -> (fun _ -> Unknown)),
        Ptp "p",
        Operation "makeO",
        [],
        [(VarT "int", Var "a")],
        [(Var "off", Dvar(Var("a"))); 
        (Var "u", PtID(Ptp "p"))],
        (fun p -> match p with | Ptp "p" -> (fun  r -> if r = Role "B" then Top else Unknown) | _ -> (fun _ -> Unknown)),
        ""
      ),
      State "q2"
    ); (
      State "q2",
      (
        (Val (BoolVal(true)), []),
        (fun p -> match p with | Ptp "p" -> (fun  r -> if r = Role "O" then Top else Unknown) | _ -> (fun _ -> Unknown)),
        Ptp "p",
        Operation "accept",
        [],
        [],
        [],
        (fun p -> match p with | _ -> (fun _ -> Unknown)),
        ""
      ),
      State "q3"
    ); (
      State "q2",
      (
        (Val (BoolVal(true)), [(
          FuncCallEdamWrite(
              "C20", 
              Operation("transfer"), 
              [Dvar(Var("u"))], 
              [Dvar (Var "off")]
          ), true)]),
        (fun p -> match p with | Ptp "p" -> (fun  r -> if r = Role "O" then Top else Unknown) | _ -> (fun _ -> Unknown)),
        Ptp "p",
        Operation "reject",
        [],
        [],
        [],
        (fun p -> match p with | _ -> (fun _ -> Unknown)),
        ""
      ),
      State "q1"
    )];
  final_modes = []; 
  initial_state = State "_";
  roles_list = [Role "O"; Role "B"];
  ptp_var_list = [];
  variables_list = [Var "des"; Var "pr"; Var "off"; Var "u"]
}

let list_of_vars = [(VarT "string", Var "des"); (VarT "int", Var "pr"); (VarT "int", Var "off"); (VarT "user", Var "u"); (VarT "C20", Var "C20")]


let pi_cm = fun _ -> []
(* Define the initial EDAM configuration *)
let initial_config_cm = {
  state = State "_";
  pi = pi_cm;
  sigma = initialize_sigma list_of_vars;
}

(* Add to the multi_config *)
let () =
  Hashtbl.add configurations.edam_map cm_instance.name cm_instance;
  Hashtbl.add configurations.config_map cm_instance.name initial_config_cm




(* Define the dependencies map for all EDAMs *)
let dependencies_map : dependencies_map = 
  let tbl = Hashtbl.create 2 in
(* Define the dependency for c20 *)
  let dependency_c20 = {
    required_calls = [];
    participant_roles = [];
    can_generate_participants = [];
    can_generate_participants_vars = [];
    transition_probabilities = Hashtbl.create 10;
  } in
  Hashtbl.add tbl c20_instance.name dependency_c20;


  (* Define the dependency for cm *)
  let dependency_cm = {
    required_calls = [];
    participant_roles = [];
    can_generate_participants = [];
    can_generate_participants_vars = [];
    transition_probabilities = Hashtbl.create 10;
  } in
  Hashtbl.add tbl cm_instance.name dependency_cm;
  tbl


let user = PID "user"
let alice = PID "alice"
let bob = PID "bob"

let calls_list = [("Cm", (user, Operation "start", [], [StrVal "bike"; IntVal 100]));
  ("C20", (alice, Operation "start", [], [IntVal 100; StrVal "token"; StrVal "TKN"; IntVal 0]));
  ("C20", (alice, Operation "transfer", [bob], [IntVal 100]));
  ("Cm", (bob, Operation "makeO", [], [IntVal 100]));
  ("C20", (bob, Operation "approve", [PID "Cm"], [IntVal 100]));
  ("Cm", (bob, Operation "makeO", [], [IntVal 100]));
  ("Cm", (alice, Operation "accept", [], []));
  ("Cm", (user, Operation "accept", [], []));]

let () = 
  let (evaluated_trace, conf) = Core_functions.evaluate_trace calls_list configurations in
  Printer.print_trace evaluated_trace;
  Printer.print_all_sigmas conf;
