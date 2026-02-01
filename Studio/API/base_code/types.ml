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

(*PtpEqPtp(PtID(Ptp("_token_addr")), PtID(Ptp("Token2")))

PtpEqPtp(Ptp("_token_addr"), Ptp("Token1"))

Equal(PtID(Ptp("_token_addr")), Val(StrVal("Token2")))
*)