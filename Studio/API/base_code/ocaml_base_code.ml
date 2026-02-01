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
  
  | Self of string
  | PtID of ptp_var
  | FuncCall of string * exp list
  | FuncCallEdamRead of string * exp  
 

type funcCallEdamWrite = FuncCallEdamWrite of string * operation * (exp list) * (exp list) 


(* Expressions *)
type z3_exp =
  | Z_Exp of exp
  | Z_Call of funcCallEdamWrite
  | Z_And of z3_exp * z3_exp
  | Z_Eq of funcCallEdamWrite * bool


(* Type definitions for mappings, assignments, and states *)
type role_set = role_type list
let empty_role_set : role_set = []
type assignment_type = dvar * exp
type role_mode_type = role_type -> role_mode
type role_a_type = ptp_var -> role_mode_type
type pi_type = participant -> role_set
type sigma_type = dvar -> value_type
type iota_type = ptp_var -> participant   
type guard_type = exp * ((funcCallEdamWrite * bool) list)

(* Label and state types *)
type label_type = 
  guard_type * 
  role_a_type * 
  ptp_var * 
  operation * 
  (ptp_var list) * 
  ((dvar_type * dvar) list) * 
  (assignment_type list) * 
  role_a_type *
  string

type label_conf = participant * operation * (participant list) * (value_type list) 
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

type participant_calls = (participant * ((string * label_conf) list)) list

(* Configuration type for multiple EDAMs *)
type multi_config = {
  edam_map: (string, edam_type) Hashtbl.t;
  config_map: (string, configuration) Hashtbl.t;
}

type perform_transition_type = 
  string -> configuration -> label_conf -> edam_type -> iota_type -> multi_config -> string list -> 
  (configuration option * edam_type option * multi_config option * transition_type option * string option) option 


let perform_transition: perform_transition_type ref = ref (fun _ _ _ _ _ _ _ -> None)

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
  probability_right_participant: float;
  probability_true_for_bool: float;
  min_int_value: int;
  max_int_value: int;
  max_gen_array_size: int;
  min_gen_string_length: int;
  max_gen_string_length: int;
  z3_check_enabled: bool;
  max_fail_try: int;

  (* Keeps the latest transition executed for each EDAM, keyed by EDAM name *)
  latest_transitions: (string, transition_type option) Hashtbl.t;

  (* Keeps a log of executed operations per (EDAM name, state), including timestamp, primary participant, operation, participants, and variable info *)
  executed_operations_log: (string * state_type, (string * participant * operation * (participant list) * (dvar * value_type) list) list) Hashtbl.t;

  (* Flag to add Pi to test *)
  add_pi_to_test: bool;
  add_test_of_state: bool;
  add_test_of_variables: bool;
}


(* Type to represent deployment information *)
type deployment_info = {
  edam_name: string;          (* Name of the EDAM *)
  params: string list;         (* Names of dependent EDAMs needed for deployment *)
}


(* Validate edams *)
let validate_edams (edam : edam_type) : bool =
  (* Extract state names *)
  let state_names = List.map (fun (State s) -> s) edam.states in

  (* Ensure states list is not empty and does not contain "_" *)
  let states_not_empty = state_names <> [] in
  let states_does_not_contain_underscore = not (List.exists (fun s -> s = "_" || s = "") state_names) in

  (* Validate initial state *)
  let valid_initial_state = match edam.initial_state with State s -> s = "_" in

  (* Split transitions *)
  let start_transitions =
    List.filter (fun (from_state, (_, _, _, op, _, _, _, _, _), _) ->
      op = Operation "start"
    ) edam.transitions
  in
  let other_transitions =
    List.filter (fun (from_state, (_, _, _, op, _, _, _, _, _), _) ->
      op <> Operation "start"
    ) edam.transitions
  in

  (* Validate transitions' states *)
  let transition_states_valid =
    List.for_all (fun (from_state, _, to_state) ->
      match from_state, to_state with
      | State from_s, State to_s ->
        if from_s = "_" then
          (* Only allow "_" as from_state for the unique start transition *)
          true
        else
          List.mem from_s state_names && List.mem to_s state_names
    ) edam.transitions
  in

  match start_transitions with
  | [(State "_", (_, _, _, _, _, _, _, _, _), State target)] ->
      let target_in_states = List.mem target state_names in
      let valid_other_transitions =
        List.for_all (fun (State from_s, _, State to_s) ->
          from_s <> "_" && to_s <> "_" &&
          List.mem from_s state_names && List.mem to_s state_names
        ) other_transitions
      in
      states_not_empty &&
      states_does_not_contain_underscore &&
      valid_initial_state &&
      target_in_states &&
      transition_states_valid &&
      valid_other_transitions
  | _ -> false


(* Function to convert a guard_type into a z3_exp *)
let guard_to_z3_exp (guard: guard_type) : z3_exp =
  let (main_exp, calls) = guard in
  
  (* Convert each (FuncCallEdamWrite, bool) pair into an equality expression *)
  let call_expressions = List.map (fun (call, expected_bool) -> Z_Eq (call, expected_bool)) calls in

  (* Fold the list into a conjunction of all expressions *)
  let combined_calls = 
    match call_expressions with
    | [] -> Z_Exp main_exp  (* If no function calls, return only the main expression *)
    | _ -> List.fold_left (fun acc expr -> Z_And (acc, expr)) (Z_Exp main_exp) call_expressions
  in
  combined_calls


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

      (* Convert a z3_exp into a textual representation resembling Python syntax *)
let rec exp_to_text (e: z3_exp): string =
  match e with
  | Z_Exp exp -> exp_to_text_helper exp
  | Z_Call (FuncCallEdamWrite (edam_name, Operation op, ptp_params, data_params)) ->
      let ptp_text = String.concat ", " (List.map exp_to_text_helper ptp_params) in
      let data_text = String.concat ", " (List.map exp_to_text_helper data_params) in
      Printf.sprintf "FuncCallEdamWrite(\"%s\", \"%s\", [%s], [%s])" edam_name op ptp_text data_text
  | Z_And (e1, e2) -> Printf.sprintf "And(%s, %s)" (exp_to_text e1) (exp_to_text e2)
  | Z_Eq (call, bool_val) -> Printf.sprintf "Equal(%s, %s)" (exp_to_text (Z_Call call)) (match bool_val with |true -> "True" | false -> "False")

(* Helper function to convert exp into text *)
and exp_to_text_helper (e: exp): string =
  match e with
  | Pvar_a (Ptp ptp) -> Printf.sprintf "Ptp(\"%s\")" ptp
  | Dvar (Var var) -> Printf.sprintf "Dvar(\"%s\")" var
  | Plus (e1, e2) -> Printf.sprintf "Plus(%s, %s)" (exp_to_text_helper e1) (exp_to_text_helper e2)
  | Minus (e1, e2) -> Printf.sprintf "Minus(%s, %s)" (exp_to_text_helper e1) (exp_to_text_helper e2)
  | Times (e1, e2) -> Printf.sprintf "Times(%s, %s)" (exp_to_text_helper e1) (exp_to_text_helper e2)
  | Divide (e1, e2) -> Printf.sprintf "Divide(%s, %s)" (exp_to_text_helper e1) (exp_to_text_helper e2)
  | ListIndex (lst, idx, default) ->
      Printf.sprintf "ListIndex(%s, %s, %s)" (exp_to_text_helper lst) (exp_to_text_helper idx) (exp_to_text_helper default)
  | MapIndex (map, key, default) ->
      Printf.sprintf "MapIndex(%s, %s, %s)" (exp_to_text_helper map) (exp_to_text_helper key) (exp_to_text_helper default)
  | And (e1, e2) -> Printf.sprintf "And(%s, %s)" (exp_to_text_helper e1) (exp_to_text_helper e2)
  | Or (e1, e2) -> Printf.sprintf "Or(%s, %s)" (exp_to_text_helper e1) (exp_to_text_helper e2)
  | Not e -> Printf.sprintf "Not(%s)" (exp_to_text_helper e)
  | PtpEqPtp (Ptp p1, Ptp p2) -> Printf.sprintf "PtpEqPtp(Ptp(\"%s\"), Ptp(\"%s\"))" p1 p2
  | GreaterThan (e1, e2) -> Printf.sprintf "GreaterThan(%s, %s)" (exp_to_text_helper e1) (exp_to_text_helper e2)
  | GreaterThanEqual (e1, e2) -> Printf.sprintf "GreaterThanEqual(%s, %s)" (exp_to_text_helper e1) (exp_to_text_helper e2)
  | LessThan (e1, e2) -> Printf.sprintf "LessThan(%s, %s)" (exp_to_text_helper e1) (exp_to_text_helper e2)
  | LessThanEqual (e1, e2) -> Printf.sprintf "LessThanEqual(%s, %s)" (exp_to_text_helper e1) (exp_to_text_helper e2)
  | Equal (e1, e2) -> Printf.sprintf "Equal(%s, %s)" (exp_to_text_helper e1) (exp_to_text_helper e2)
  | NotEqual (e1, e2) -> Printf.sprintf "Not(Equal(%s, %s))" (exp_to_text_helper e1) (exp_to_text_helper e2)
  | Val v -> Printf.sprintf "Val(%s)" (value_type_to_text v)
  | Self self_name -> Printf.sprintf "Self()"
  | PtID (Ptp ptp) -> Printf.sprintf "PtID(Ptp(\"%s\"))" ptp
  | FuncCall (name, args) ->
      let args_text = String.concat ", " (List.map exp_to_text_helper args) in
      Printf.sprintf "FuncCall(\"%s\", [%s])" name args_text
  | FuncCallEdamRead (edam_name, exp) ->
      Printf.sprintf "FuncCallEdamRead(\"%s\", %s)" edam_name (exp_to_text_helper exp)
  | _ -> failwith "Unsupported expression type"

let list_calls_to_text (calls) : string =
  let call_expressions = List.map (fun (call, expected_bool) -> Z_Eq (call, expected_bool)) calls in
  call_expressions
    |> List.map exp_to_text
    |> String.concat ", "
    |> Printf.sprintf "[%s]"


let generate_python_edam (edam: edam_type) contract_vars : string =
  if not (validate_edams edam) then 
    failwith "Not valid edam"
  else (

    
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
       |> List.map (fun (VarT dtype, Var name) ->
           Printf.sprintf "(\"%s\", Dvar(\"%s\"))" 
             dtype name)
       |> String.concat ", "
       |> Printf.sprintf "[%s]"
    in

  (* Convert transitions to Python list *)
  let transitions =
    edam.transitions
    |> List.map (fun (data : transition_type) ->
        let State src, (guard, rho, Ptp ptp_var, Operation op, ptp_vars, data_params, assignments, rho_prime, _), State dst = data in
        let (main_guard_exp, list_calls) = guard in
        let guard_text = exp_to_text (guard_to_z3_exp (main_guard_exp, [])) in
        let list_calls_text = list_calls_to_text list_calls in
         let assignments_text =
           assignments
           |> List.map (fun (Var lhs, rhs) -> Printf.sprintf "(Dvar(\"%s\"), %s)" lhs (exp_to_text (guard_to_z3_exp (rhs,[]))))
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
         let pi_json = generate_ptp_roles_modes rho ((Ptp ptp_var)::ptp_vars) edam.roles_list in
         let pi_prime_json = generate_ptp_roles_modes rho_prime ((Ptp ptp_var)::ptp_vars) edam.roles_list in
         Printf.sprintf "Transition(source_state=\"%s\", guard=%s, external_calls=%s, roles=%s, participants=%s, initiator=\"%s\", operation=\"%s\", parameters=%s, assignments=%s, role_updates=%s,  target_state=\"%s\")"
        src guard_text list_calls_text pi_json ptp_vars_text ptp_var op data_params_text assignments_text pi_prime_json dst
       )
    |> String.concat ",\n"
    |> Printf.sprintf "[%s]"
  in

  (* Generate the Python code for the EDAM *)
  Printf.sprintf
    "
EDAM(\nname=\"%s\", \nstates=%s,\ntransitions=%s,\ninitial_state=\"_\",\nfinal_states=%s,\nroles_list=%s,\nvariables_list=%s,\nparticipants_list={},\ncontract_data_types=%s\n)\n
    "
    edam.name
    states
    transitions
    (*(match edam.initial_state with State s -> s)*)
    (edam.final_modes |> List.map (function State s -> s) |> list_to_python)
    roles_list
    variables_list
    contract_vars_text
  )
