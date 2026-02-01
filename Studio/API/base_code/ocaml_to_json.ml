(* Type Definitions and Declarations *)
type ptp_var = Ptp of string
type participant = PID of string
type role_type = Role of string
type role_mode = Top | Bottom | Unknown
type operation = Operation of string
type dvar_type = VarT of string
type dvar = Var of string

type value_type =
  | BoolVal of bool
  | IntVal of int
  | StrVal of string
  | PtpID of participant
  | ListVal of value_type list
  | MapVal of (value_type * value_type) list

(* Expressions *)
type exp =
  | Pvar_a of ptp_var
  | Dvar of dvar
  
  (* Arithmetic expressions *)
  | Plus of exp * exp
  | Minus of exp * exp
  | Times of exp * exp
  | Divide of exp * exp
  | ListIndex of exp * exp * exp  (* List, Index, Default Value *)
  | MapIndex of exp * exp * exp   (* Map, Key, Default Value *)

  (* Boolean expressions *)
  | And of exp * exp
  | Or of exp * exp
  | Not of exp
  | PtpEqPtp of ptp_var * ptp_var
  | GreaterThan of exp * exp
  | GreaterThanEqual of exp * exp
  | LessThan of exp * exp
  | LessThanEqual of exp * exp
  | Equal of exp * exp
  | NotEqual of exp * exp

  (* Value types *)
  | Val of value_type
  
  | PtID of ptp_var
  | FuncCall of string * exp list
  | FuncCallEdamRead of string * exp  
  | FuncCallEdamWrite of string * operation * (exp list) * (exp list)
  

(* Type definitions for mappings, assignments, and states *)
type role_set = role_type list
let empty_role_set : role_set = []
type assignment_type = dvar * exp
type role_mode_type = role_type -> role_mode
type role_a_type = ptp_var -> role_mode_type
type pi_type = participant -> role_set
type sigma_type = dvar -> value_type
type iota_type = ptp_var -> participant
type guard_type = exp

(* Label and state types *)
type label_type = 
  guard_type * 
  role_a_type * 
  (ptp_var list) * 
  ptp_var * 
  operation * 
  ((dvar_type * dvar) list) * 
  (assignment_type list) * 
  role_a_type *
  string

type label_conf = participant * operation * (value_type list) * (participant list)
type state_type = State of string
type transition_type = state_type * label_type * state_type 
type state_set = state_type list
type transition_set = transition_type list

(* EDAM type and configuration *)
type configuration = {
  state: state_type;
  pi: pi_type;
  sigma: sigma_type;
}

type edam_type = {
  name: string;
  states: state_set;
  transitions: transition_set;
  final_modes: state_set;
  initial_state: state_type;
  roles_list: role_type list;
  ptp_var_list: ptp_var list;
  variables_list: dvar list;
}

type transition_call = string * label_conf

type participant_calls = (participant * ((string * label_conf * iota_type) list)) list

(* Configuration type for multiple EDAMs *)
type multi_config = {
  edam_map: (string, edam_type) Hashtbl.t;
  config_map: (string, configuration) Hashtbl.t;
}

type perform_transition_type = 
  configuration -> label_conf -> edam_type -> iota_type -> multi_config -> (configuration * edam_type * multi_config * transition_type) option

let perform_transition: perform_transition_type ref = ref (fun _ _ _ _ _ -> None)

(* Add a new field to represent transition probabilities *)
type transition_probability_map = (state_type * operation, float) Hashtbl.t

(* Add it to the dependencies map *)
type dependancy_type = {
  required_calls: (state_type * operation * (operation list)) list;
  participant_roles: (role_type * participant list) list;
  can_generate_participants: (state_type * operation * bool) list;
  can_generate_participants_vars: (state_type * operation * bool) list;
  transition_probabilities: transition_probability_map; 
}


(* dependencies_map maps EDAM names (strings) to their dependency types *)
type dependencies_map = (string, dependancy_type) Hashtbl.t

(* Define a type for server configuration *)
type global_edam_configs= {
  shared_roles: float;
  }


(* Define a type for server configuration *)
type server_config_type = {
  probability_new_participant: float;
  probability_true_for_bool: float;
  min_int_value: int;
  max_int_value: int;
  max_gen_array_size: int;
  min_gen_string_length: int;
  max_gen_string_length: int;
  z3_check_enabled: bool;

  (* Keeps the latest transition executed for each EDAM, keyed by EDAM name *)
  latest_transitions: (string, transition_type option) Hashtbl.t;

  (* Keeps a log of executed operations per (EDAM name, state), including timestamp, primary participant, operation, participants, and variable info *)
  executed_operations_log: (string * state_type, (string * participant * operation * (participant list) * (dvar * value_type) list) list) Hashtbl.t;
}


(* Define the function *)
let generate_ptp_roles_modes 
  (rho: role_a_type) 
  (ptp_vars: ptp_var list) 
  (roles: role_type list) : string =

  (* Helper function to convert role_mode to string *)
  let role_mode_to_string = function
    | Top -> "\"Top\""
    | Bottom -> "\"Bottom\""
    | Unknown -> "\"Unknown\""
  in

  (* Helper function to convert roles and modes into JSON text *)
  let roles_modes_to_json roles_modes =
    roles_modes
    |> List.map (fun (Role role, mode) ->
           Printf.sprintf "\"%s\": %s" role (role_mode_to_string mode))
    |> String.concat ", "
    |> Printf.sprintf "{%s}"
  in

  (* Helper function to get roles and modes for a participant *)
  let get_roles_and_modes ptp_var =
    (* Retrieve the role_mode_type (role mapping) for the participant *)
    let role_m = rho ptp_var in
    (* Map each role to its corresponding mode using the rho mapping *)
    let roles_modes = 
      List.map (fun role ->
        let mode = role_m role in
        (role, mode)  (* Return (role, mode) pair *)
      ) roles
    in
    (* Convert the participant and roles_modes to JSON text *)
    match ptp_var with
    | Ptp ptp ->
      Printf.sprintf "\"%s\": %s" ptp (roles_modes_to_json roles_modes)
  in

  (* Map each ptp_var to its participant and associated roles and modes *)
  ptp_vars
  |> List.map get_roles_and_modes
  |> String.concat ", "
  |> Printf.sprintf "{%s}"




(* Convert a value_type into a textual representation *)
let rec value_type_to_text (v: value_type): string =
  match v with
  | BoolVal b -> Printf.sprintf "%s" (match b with |true -> "True" | false -> "False")
  | IntVal i -> Printf.sprintf "%d" i
  | StrVal s -> Printf.sprintf "\"%s\"" s
  | PtpID (PID p) -> Printf.sprintf "PtpID(\"%s\")" p
  | ListVal lst ->
      let elements = String.concat ", " (List.map value_type_to_text lst) in
      Printf.sprintf "[%s]" elements
  | MapVal lst ->
      let mappings = String.concat ", " (List.map (fun (k, v) -> Printf.sprintf "(%s, %s)" (value_type_to_text k) (value_type_to_text v)) lst) in
      Printf.sprintf "{%s}" mappings

(* Convert an expression into a textual representation resembling Python syntax *)
let rec exp_to_text (e: exp): string =
  match e with
  | Pvar_a (Ptp ptp) -> Printf.sprintf "Ptp(\"%s\")" ptp
  | Dvar (Var var) -> Printf.sprintf "Dvar(\"%s\")" var
  | Plus (e1, e2) -> Printf.sprintf "Plus(%s, %s)" (exp_to_text e1) (exp_to_text e2)
  | Minus (e1, e2) -> Printf.sprintf "Minus(%s, %s)" (exp_to_text e1) (exp_to_text e2)
  | Times (e1, e2) -> Printf.sprintf "Times(%s, %s)" (exp_to_text e1) (exp_to_text e2)
  | Divide (e1, e2) -> Printf.sprintf "Divide(%s, %s)" (exp_to_text e1) (exp_to_text e2)
  | ListIndex (lst, idx, default) ->
      Printf.sprintf "ListIndex(%s, %s, %s)" (exp_to_text lst) (exp_to_text idx) (exp_to_text default)
  | MapIndex (map, key, default) ->
      Printf.sprintf "MapIndex(%s, %s, %s)" (exp_to_text map) (exp_to_text key) (exp_to_text default)
  | And (e1, e2) -> Printf.sprintf "And(%s, %s)" (exp_to_text e1) (exp_to_text e2)
  | Or (e1, e2) -> Printf.sprintf "Or(%s, %s)" (exp_to_text e1) (exp_to_text e2)
  | Not e -> Printf.sprintf "Not(%s)" (exp_to_text e)
  | PtpEqPtp (Ptp p1, Ptp p2) -> Printf.sprintf "PtpEqPtp(Ptp(\"%s\"), Ptp(\"%s\"))" p1 p2
  | GreaterThan (e1, e2) -> Printf.sprintf "GreaterThan(%s, %s)" (exp_to_text e1) (exp_to_text e2)
  | GreaterThanEqual (e1, e2) -> Printf.sprintf "GreaterThanEqual(%s, %s)" (exp_to_text e1) (exp_to_text e2)
  | LessThan (e1, e2) -> Printf.sprintf "LessThan(%s, %s)" (exp_to_text e1) (exp_to_text e2)
  | LessThanEqual (e1, e2) -> Printf.sprintf "LessThanEqual(%s, %s)" (exp_to_text e1) (exp_to_text e2)
  | Equal (e1, e2) -> Printf.sprintf "Equal(%s, %s)" (exp_to_text e1) (exp_to_text e2)
  | NotEqual (e1, e2) -> Printf.sprintf "Not(Equal(%s, %s))" (exp_to_text e1) (exp_to_text e2)
  | Val v -> Printf.sprintf "Val(%s)" (value_type_to_text v)
  | PtID (Ptp ptp) -> Printf.sprintf "PtID(Ptp(\"%s\"))" ptp
  | FuncCall (name, args) ->
      let args_text = String.concat ", " (List.map exp_to_text args) in
      Printf.sprintf "FuncCall(\"%s\", [%s])" name args_text
  | FuncCallEdamRead (edam_name, exp) ->
      Printf.sprintf "FuncCallEdamRead(\"%s\", %s)" edam_name (exp_to_text exp)
  | FuncCallEdamWrite (edam_name, Operation op, ptp_params, data_params) ->
      let ptp_text = String.concat ", " (List.map exp_to_text ptp_params) in
      let data_text = String.concat ", " (List.map exp_to_text data_params) in
      Printf.sprintf "FuncCallEdamWrite(\"%s\", \"%s\", [%s], [%s])" edam_name op ptp_text data_text


let generate_python_edam (edam: edam_type) contract_vars : string =
  (* Helper function to convert a list of strings to a Python list *)
  let list_to_python lst =
    lst |> List.map (fun s -> Printf.sprintf "\"%s\"" s) |> String.concat ", " |> Printf.sprintf "[%s]"
  in

  (* Convert states to Python list *)
  let states =
    edam.states
    |> List.map (function State state -> state)
    |> list_to_python
  in

  (* Convert roles to Python list *)
  let roles_list =
    edam.roles_list
    |> List.map (function Role role -> role)
    |> list_to_python
  in

  (* Convert variables to Python list *)
  let variables_list =
    edam.variables_list
    |> List.map (function Var var -> var)
    |> list_to_python
  in
  let contract_vars_text = 
       contract_vars
       |> List.map (fun (Var dtype, Var name) ->
           Printf.sprintf "(\"%s\", Dvar(\"%s\"))" 
             dtype name)
       |> String.concat ", "
       |> Printf.sprintf "[%s]"
    in

  (* Convert transitions to Python list *)
  let transitions =
    edam.transitions
    |> List.map (fun (data : transition_type) ->
        let State src, (guard, rho, ptp_vars, Ptp ptp_var, Operation op, data_params, assignments, rho_prime, _), State dst = data in
         let guard_text = exp_to_text guard in
         let assignments_text =
           assignments
           |> List.map (fun (Var lhs, rhs) -> Printf.sprintf "(Dvar(\"%s\"), %s)" lhs (exp_to_text rhs))
           |> String.concat ", "
           |> Printf.sprintf "[%s]"
         in
         let ptp_vars_text =
           ptp_vars
           |> List.map (function Ptp ptp -> ptp)
           |> list_to_python
         in
         (*let contract_vars_text =
           if op != "start" then "[]" else contract_vars_text_
         in*)
         let data_params_text =
           data_params
           |> List.map (fun (VarT dtype, Var name) ->
               Printf.sprintf "(\"%s\", Dvar(\"%s\"))" 
                 dtype name)
           |> String.concat ", "
           |> Printf.sprintf "[%s]"
        in
         let rho_json = generate_ptp_roles_modes rho ((Ptp ptp_var)::ptp_vars) edam.roles_list in
         let rho_prime_json = generate_ptp_roles_modes rho_prime ((Ptp ptp_var)::ptp_vars) edam.roles_list in
         Printf.sprintf "
         Transition(source_state=\"%s\", guard=%s, roles=%s, participants=%s, initiator=\"%s\", operation=\"%s\", parameters=%s, assignments=%s, role_updates=%s, contract_data_types=%s,  target_state=\"%s\")"
        src guard_text rho_json ptp_vars_text ptp_var op data_params_text assignments_text rho_prime_json contract_vars_text dst
       )
    |> String.concat ","
    |> Printf.sprintf "[%s]"
  in

  (* Generate the Python code for the EDAM *)
  Printf.sprintf
    "
edam_instance = EDAM(\n name=\"%s\",\n states=%s,\n transitions=%s,\n initial_state=\"%s\",\n final_states=%s,\n roles_list=%s,\n variables_list=%s,\n participants_list={}  # To be filled dynamically \n)
    "
    edam.name
    states
    transitions
    (match edam.initial_state with State s -> s)
    (edam.final_modes |> List.map (function State s -> s) |> list_to_python)
    roles_list
    variables_list



(* Define the participants *)
let owner = PID "Owner"
let alice = PID "Alice"
let bob = PID "Bob"

(* Define the state types *)
let state_init = State "S_Init"
let state_deployed = State "S_Deployed"
let state_transferred = State "S_Transferred"
let state_approved = State "S_Approved"
let state_minted = State "S_Minted"
let state_burned = State "S_Burned"

(* Define the operations *)
let operation_deploy = Operation "start"
let operation_mint = Operation "mint"
let operation_transfer = Operation "transfer"
let operation_approve = Operation "approve"
let operation_transfer_from = Operation "transferFrom"
let operation_burn = Operation "burn"

(* Define the roles *)
let role_owner = Role "owner"
let role_user = Role "user"

(* Define the role mappings *)
let rho_owner : role_a_type = fun _ -> fun _ -> Bottom
let rho_user : role_a_type = fun (p : ptp_var) -> match p with
  | Ptp "owner" -> (fun r -> if r = role_owner then Top else Unknown)
  | Ptp "alice" -> (fun r -> if r = role_user then Top else Unknown)
  | Ptp "bob" -> (fun r -> if r = role_user then Top else Unknown)
  | _ -> (fun _ -> Unknown)

let rho_owner_prime: role_a_type = fun (p : ptp_var) -> match p with
  | Ptp "owner" -> (fun r -> if r = role_owner then Top else Unknown)
  | _ -> (fun _ -> Unknown)
  
let rho_user_top: role_a_type = fun (p : ptp_var) -> match p with
  | Ptp "user" -> (fun r -> if r = role_user then Top else Unknown)
  | _ -> (fun _ -> Unknown)
  
let rho_user_prime: role_a_type = fun (p : ptp_var) -> match p with
  | Ptp "user" | Ptp "recipient" | Ptp "spender" -> (fun r -> if r = role_user then Top else Unknown)
  | _ -> (fun _ -> Unknown)

let rho_prime_do_not_care : role_a_type = fun _ -> fun _ -> Unknown


(* Define the transitions *)
let transition_deploy: transition_type  = (
  state_init,
  (
    Val (BoolVal true), 
    rho_prime_do_not_care, 
    [], 
    Ptp "owner", 
    operation_deploy, 
    [(Var "int", Var "initialSupply")], 
    [
      (Var "totalSupply", Dvar (Var "initialSupply"));
      (Var "balances", FuncCall ("update_map", [
        Dvar (Var "balances");
        PtID (Ptp "owner");
        Dvar (Var "initialSupply")
      ]))
    ], 
    rho_owner_prime, 
    "Deploy"
  ),
  state_deployed
)

let transition_mint: transition_type  = (
  state_deployed,
  (
    GreaterThan(Dvar (Var "_amount"), Val (IntVal 0)), 
    rho_owner_prime, 
    [Ptp "user"], 
    Ptp "owner", 
    operation_mint, 
    [(Var "int", Var "_amount")], 
    [
      (Var "totalSupply", Plus (Dvar (Var "totalSupply"), Dvar (Var "_amount")));
      (Var "balances", FuncCall ("update_map", [
        Dvar (Var "balances");
        PtID (Ptp "user");
        Plus (
          MapIndex (Dvar (Var "balances"), PtID (Ptp "user"), Val (IntVal 0)), 
          Dvar (Var "_amount")
        )
      ]))
    ], 
    rho_user_top, 
    "Mint"
  ),
  state_deployed
)

let transition_transfer: transition_type  = (
  state_deployed,
  (
    GreaterThanEqual (MapIndex (Dvar (Var "balances"), PtID (Ptp "user"), Val (IntVal 0)), Dvar (Var "_amount")) 
    , 
    rho_user_top, 
    [Ptp "recipient"], 
    Ptp "user", 
    operation_transfer, 
    [(Var "int", Var "_amount")], 
    [
      (Var "balances", FuncCall ("update_map", [
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
      ]))
    ], 
    rho_user_prime, 
    "Transfer"
  ),
  state_deployed
)

let transition_approve: transition_type  = (
  state_deployed,
  (
    Val (BoolVal true), 
    rho_prime_do_not_care,
    [Ptp "spender"], 
    Ptp "user", 
    operation_approve, 
    [(Var "int", Var "_amount")], 
    [(Var "allowances", FuncCall ("update_nested_map", [
      Dvar (Var "allowances");
      PtID (Ptp "user");
      PtID (Ptp "spender");
      Dvar (Var "_amount")
    ]))], 
    rho_user_prime, 
    "Approve"
  ),
  state_deployed
)

let transition_transfer_from: transition_type  = (
  state_deployed,
  (
    And (
      GreaterThanEqual (
        MapIndex (
          MapIndex (
            Dvar (Var "allowances"), 
            PtID (Ptp "sender"), Val (MapVal [])
          ), 
          PtID (Ptp "user"), 
          Val (IntVal 0)
        ), Dvar (Var "_amount")),
      GreaterThanEqual (
        MapIndex (Dvar (Var "balances"), PtID (Ptp "sender"), Val (IntVal 0)), 
        Dvar (Var "_amount")
      ) 
    )
    ,
    rho_prime_do_not_care,
    [Ptp "sender"; Ptp "recipient"],
    Ptp "user",
    operation_transfer_from,
    [(Var "int", Var "_amount")],
    [
      (Var "balances", FuncCall ("update_map", [
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
      ]));
      (Var "allowances", FuncCall ("update_nested_map", [
        Dvar (Var "allowances"); 
        PtID (Ptp "sender"); 
        PtID (Ptp "user"); 
        Minus (MapIndex (MapIndex (Dvar (Var "allowances"), PtID (Ptp "sender"), Val (MapVal [])), PtID (Ptp "user"), Val (IntVal 0)), Dvar (Var "_amount"))
      ]))
    ],
    rho_user_prime,  
    "TransferFrom"
  ),
  state_deployed
)

let transition_burn: transition_type  = (
  state_deployed,
  (
    GreaterThanEqual (MapIndex (Dvar (Var "balances"), PtID (Ptp "user"), Val (IntVal 0)), Dvar (Var "_amount")) 
    , 
    rho_prime_do_not_care, 
    [], 
    Ptp "user", 
    operation_burn, 
    [(Var "int", Var "_amount")], 
    [
      (Var "totalSupply", Minus (Dvar (Var "totalSupply"), Dvar (Var "_amount")));
      (Var "balances", FuncCall ("update_map", [
        Dvar (Var "balances");
        PtID (Ptp "user");
        Minus (MapIndex (Dvar (Var "balances"), PtID (Ptp "user"), Val (IntVal 0)), Dvar (Var "_amount"))
      ]))
    ], 
    rho_prime_do_not_care, 
    "Burn"
  ),
  state_deployed
)

(* Create the set of transitions *)
let transitions_tokens : transition_set = [
  transition_deploy;
  transition_mint;
  transition_transfer;
  transition_approve;
  transition_transfer_from;
  transition_burn
]



(* Define the EDAM *)
let edam : edam_type = {
  name = "ERC20Token1";
  states = [state_init; state_deployed; state_transferred; state_approved; state_minted; state_burned];
  transitions = transitions_tokens;
  final_modes = [state_burned];
  initial_state = state_init;
  roles_list = [role_owner; role_user];
  ptp_var_list = [];
  variables_list = [Var "totalSupply"; Var "balances"; Var "allowances"]
}


let () = Printf.printf "%s" (generate_python_edam edam [(Var "map_map_address_address_int", Var "allowances");(Var "map_address_int", Var "balances");(Var "int", Var "totalSupply")])
