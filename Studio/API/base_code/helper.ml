(* helper.ml *)
open Types
open Printf
open Random
open Printer
open Printexc  

(* Generic function to safely retrieve a value from a hash table *)
let find_with_debug (table: ('a, 'b) Hashtbl.t) (key: 'a)  : 'b =
  try
    Hashtbl.find table key
  with Not_found ->
    Printf.eprintf "❌ Error: Key '%s' not found in hash table.\n"  key;
    Printf.eprintf "🔍 Stack trace:\n%s\n" (Printexc.get_backtrace ());
    failwith ("Key not found: " ^ key)


(* Helper function to deep copy sigma *)
let copy_sigma sigma : sigma_type =
  fun dvar ->
    match sigma dvar with
    | BoolVal b -> BoolVal b
    | IntVal i -> IntVal i
    | StrVal s -> StrVal s
    | PtpID pid -> PtpID pid
    | ListVal lst -> ListVal (List.map (fun v -> v) lst)
    | MapVal map -> MapVal (List.map (fun (k, v) -> (k, v)) map)
    

(* Sort states alphabetically *)
let sort_states states = 
List.sort (fun (State s1) (State s2) -> String.compare s1 s2) states

let sort_roles roles = 
List.sort (fun (Role r1) (Role r2) -> String.compare r1 r2) roles

(* Find the index of a specific state in the sorted states list *)
let get_state_index to_state sorted_states =
match List.mapi (fun idx state -> (state, idx)) sorted_states |> List.find_opt (fun (state, _) -> state = to_state) with
| Some (_, idx) -> idx
| None -> failwith "State not found in EDAM states"

(* Find the index of a specific state in the sorted states list *)
let get_roles_index a_role sorted_roles_list =
match List.mapi (fun idx (Role role_name) -> (role_name, idx)) sorted_roles_list 
      |> List.find_opt (fun (role_name, _) -> role_name = (match a_role with Role r -> r)) with
| Some (_, idx) -> idx
| None -> failwith "Role not found in EDAM roles"


(* Helper function to generate iota mapping for a given transition *)
let generate_iota (ptp_list: ptp_var list) (participants: participant list) =
  
  let updates = List.combine ptp_list participants in
  fun ptp_var ->
    match List.assoc_opt ptp_var updates with
    | Some participant -> participant
    | None -> PID ""

(* Helper function to parse index from a string *)
let parse_index parts =
  match parts with
  | ["int"; value] -> IntVal (int_of_string value)
  | ["str"; value] -> StrVal value
  | ["pid"; value] -> PtpID (PID value)
  | ["bool"; value] -> BoolVal (bool_of_string value)
  | _ -> failwith "Invalid index format"


(* Function to generate a random integer in a given range [low, high] *)
let generate_number_in_range low high =
  if low > high then
    failwith "Invalid range: low must be less than or equal to high"
  else
    low + Random.int (high - low + 1);;

  
(* Define a function to initialize the sigma mapping based on the list of variables *)
let initialize_sigma list_of_vars : sigma_type =
  let sigma = Hashtbl.create (List.length list_of_vars) in
  List.iter (fun (var_type, var_name) ->
    let default_value = match var_type with
      | VarT "int" | VarT "uint" -> IntVal 0
      | VarT "bool" -> BoolVal false
      | VarT "address" | VarT "contract" -> StrVal "0x0000000000000000000000000000000000000000"
      | VarT "user" -> PtpID (PID "")
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
    (* print_endline ("Looking up variable "  ^ (match var with Var v -> v)); *)
    match Hashtbl.find_opt sigma var with
    | Some value -> value
    (* | None -> failwith ("Variable not found in sigma: " ^ (match var with Var v -> v)) *)
  )


(* Function to deep copy a hashtable *)
let copy_hashtable tbl =
  let tbl_copy = Hashtbl.create (Hashtbl.length tbl) in
  Hashtbl.iter (fun key value -> Hashtbl.add tbl_copy key value) tbl;
  tbl_copy

(* Function to deep copy multi_config *)
let copy_multi_config (mc: Types.multi_config) : Types.multi_config =
  {
    config_map = copy_hashtable mc.config_map;  (* Copy the configuration map *)
    edam_map = copy_hashtable mc.edam_map;    (* Copy the EDAM map *)
  }


let string_of_op op = match op with Operation o -> o 
let string_of_pid pid = match pid with PID p -> p 

(* Function to convert value_type to a string *)
let rec string_of_value = function
  | BoolVal b -> string_of_bool b  (* Convert bool to string *)
  | IntVal i -> string_of_int i    (* Convert int to string *)
  | StrVal s -> "\"" ^ s ^ "\""    (* Convert string and surround with quotes *)
  | PtpID (PID p) -> "ParticipantID: " ^ p  (* Convert participant ID *)
  | ListVal lst -> 
      "[" ^ (String.concat "; " (List.map string_of_value lst)) ^ "]"  (* Convert list of values *)
  | MapVal map -> 
      "{" ^ (String.concat "; " 
        (List.map (fun (k, v) -> string_of_value k ^ ": " ^ string_of_value v) map)) ^ "}"  (* Convert map of key-value pairs *)

  
(* Helper functions *)
let update (f : 'alpha -> 'beta) (x : 'alpha) (v : 'beta) : 'alpha -> 'beta =
  fun y -> if y = x then v else f y

let add_to_set (eq : 'a -> 'a -> bool) (element : 'a) (set : 'a list) : 'a list =
  if List.exists (fun x -> eq x element) set then set else element :: set

let role_eq (r1 : role_type) (r2 : role_type) : bool =
  match r1, r2 with
  | Role s1, Role s2 -> s1 = s2

let add_role = add_to_set role_eq

let role_set_of_list (lst : role_type list) : role_set =
  List.fold_right add_role lst empty_role_set

let substitute_values (sigma: sigma_type) (sub_map: (dvar * value_type) list) : sigma_type =
  List.fold_left (fun acc (dvar, value) -> update acc dvar value) sigma sub_map

let role_modes_compatible (modeP:role_mode) (modeP':role_mode) =
  modeP = Unknown || modeP' = Unknown || modeP = modeP'

(* Helper function to convert StrVal to Operation *)
let strval_to_operation (v: value_type) : operation =
  match v with
  | StrVal s -> Operation s
  | _ -> failwith "Expected StrVal for conversion to Operation"
  
(* Helper function to get the value from a list by index *)
let rec eval_list_index (lst: value_type list) (idx: int) : value_type =
  match lst, idx with
  | [], _ -> failwith "Index out of bounds"
  | hd :: _, 0 -> hd
  | _ :: tl, n -> eval_list_index tl (n - 1)

(* Function to get the value from a map or a default value if the key does not exist *)
let get_map_value (map: (value_type * value_type) list) (key: value_type) (default: value_type) : value_type =
  try List.assoc key map with
  | Not_found -> default

(* Helper function to update a map with a new key-value pair, initializing if necessary *)
let update_map (map: (value_type * value_type) list) (key: value_type) (value: value_type) : (value_type * value_type) list =
  let map = if List.exists (fun (k, _) -> k = key) map then map else (key, value) :: map in
  List.map (fun (k, v) -> if k = key then (k, value) else (k, v)) map

(* Helper function to get the map key from a value *)
let get_key_val (key1: value_type) = 
  match key1 with
  | PtpID pid -> key1
  | IntVal i -> key1
  | StrVal s -> key1
  | BoolVal b -> key1
  | _ -> failwith "Unsupported key type for nested map"

(* Helper function to update the iota mapping *)
let update_iota iota updates =
  fun ptp_var ->
    match List.assoc_opt ptp_var updates with
    | Some participant -> participant
    | None -> iota ptp_var
    
(* Helper function to update a nested map *)
let update_nested_map (map: (value_type * value_type) list) (key1: value_type) (key2: value_type) (value: value_type): (value_type * value_type) list =
  let key1_val = get_key_val key1 in
  let key2_val = get_key_val key2 in
  let nested_map = 
    match List.assoc_opt key1_val map with
    | Some (MapVal nested) -> nested
    | None -> []
    | _ -> failwith "Expected nested map"
  in
  let updated_nested_map = (key2_val, value) :: List.remove_assoc key2_val nested_map in
  (key1_val, MapVal updated_nested_map) :: List.remove_assoc key1_val map

let get_edam_config edam_name (multi_cfg:multi_config) = 
  let edam = find_with_debug multi_cfg.edam_map edam_name in
  let config = find_with_debug multi_cfg.config_map edam_name in
  (edam, config)

  

(* Function to generate an iota mapping for a given EDAM, label_conf, and multi_config *)
let generate_iota_from_label (edam_name: string) (label_conf: label_conf) (multi_cfg: multi_config) : iota_type =
  (* Find the EDAM in multi_config *)
  let edam =
    try Hashtbl.find multi_cfg.edam_map edam_name
    with Not_found -> failwith ("EDAM not found: " ^ edam_name)
  in

  let (participant, operation, participants, values) = label_conf in

  (* Find a transition that matches the operation, participant count, and variable count *)
  let matching_transition =
    List.find_opt (fun (_, ((_, _), _, _, op, ptp_list, dvar_list_with_type, _, _, _), _) ->
      op = operation &&
      List.length ptp_list = List.length participants &&
      List.length dvar_list_with_type = List.length values
    ) edam.transitions
  in

  match matching_transition with
  | Some (_, ((_, _), _, ptp, _, ptp_list, _, _, _, _), _) ->
      (* Create an iota mapping using ptp_list and participants *)
      let iota_map = List.combine (ptp_list@[ptp; Ptp edam_name]) (participants@[participant; PID edam_name]) in
      fun ptp ->
        try List.assoc ptp iota_map
        with Not_found -> PID "Unknown"

  | _ -> failwith "No matching transition found for operation and participant/variable count."
 

(* Evaluate function for expressions *)
let rec eval (sigma: sigma_type) (iota: iota_type) (e: exp) (multi_cfg: multi_config) (called_contracts: string list) : value_type * multi_config =
  match e with
  | Pvar_a ptp_var -> (PtpID (iota ptp_var), multi_cfg)
  | Dvar dvar -> (sigma dvar, multi_cfg)
  | Plus (e1, e2) ->
      let (v1, multi_cfg1) = eval sigma iota e1 multi_cfg called_contracts in
      let (v2, multi_cfg2) = eval sigma iota e2 multi_cfg1 called_contracts in
      (match (v1, v2) with
      | IntVal i1, IntVal i2 -> (IntVal (i1 + i2), multi_cfg2)
      | _ -> failwith "Type error in Plus")
  | Minus (e1, e2) ->
      let (v1, multi_cfg1) = eval sigma iota e1 multi_cfg called_contracts in
      let (v2, multi_cfg2) = eval sigma iota e2 multi_cfg1 called_contracts in
      (match (v1, v2) with
      | IntVal i1, IntVal i2 -> (IntVal (i1 - i2), multi_cfg2)
      | _ -> failwith "Type error in Minus")
  | Times (e1, e2) ->
      let (v1, multi_cfg1) = eval sigma iota e1 multi_cfg called_contracts in
      let (v2, multi_cfg2) = eval sigma iota e2 multi_cfg1 called_contracts in
      (match (v1, v2) with
      | IntVal i1, IntVal i2 -> (IntVal (i1 * i2), multi_cfg2)
      | _ -> failwith "Type error in Times")
  | Divide (e1, e2) ->
      let (v1, multi_cfg1) = eval sigma iota e1 multi_cfg called_contracts in
      let (v2, multi_cfg2) = eval sigma iota e2 multi_cfg1 called_contracts in
      (match (v1, v2) with
      | IntVal i1, IntVal i2 -> (IntVal (i1 / i2), multi_cfg2)
      | _ -> failwith "Type error in Divide")
  | ListIndex (e1, e2, e3) ->
      let (list_val, multi_cfg1) = eval sigma iota e1 multi_cfg called_contracts in
      let (index_val, multi_cfg2) = eval sigma iota e2 multi_cfg1 called_contracts in
      let (default_val, multi_cfg3) = eval sigma iota e3 multi_cfg2 called_contracts in
      (match (list_val, index_val) with
      | ListVal lst, IntVal idx -> 
          if idx < List.length lst && idx >= 0 then (List.nth lst idx, multi_cfg3) else (default_val, multi_cfg3)
      | _ -> failwith "Type error in ListIndex")
  | MapIndex (e1, e2, e3) ->
      let (map_val, multi_cfg1) = eval sigma iota e1 multi_cfg called_contracts in
      let (key_val, multi_cfg2) = eval sigma iota e2 multi_cfg1 called_contracts in
      let (default_val, multi_cfg3) = eval sigma iota e3 multi_cfg2 called_contracts in
      (match map_val with
      | MapVal map -> 
          (try (List.assoc key_val map, multi_cfg3) with Not_found -> (default_val, multi_cfg3))
      | _ -> failwith "Type error in MapIndex")
  | And (e1, e2) ->
      let (v1, multi_cfg1) = eval sigma iota e1 multi_cfg called_contracts in
      let (v2, multi_cfg2) = eval sigma iota e2 multi_cfg1 called_contracts in
      (match (v1, v2) with
      | BoolVal b1, BoolVal b2 -> (BoolVal (b1 && b2), multi_cfg2)
      | _ -> failwith "Type error in And")
  | Or (e1, e2) ->
      let (v1, multi_cfg1) = eval sigma iota e1 multi_cfg called_contracts in
      let (v2, multi_cfg2) = eval sigma iota e2 multi_cfg1 called_contracts in
      (match (v1, v2) with
      | BoolVal b1, BoolVal b2 -> (BoolVal (b1 || b2), multi_cfg2)
      | _ -> failwith "Type error in Or")
  | Not e ->
      let (v, multi_cfg1) = eval sigma iota e multi_cfg called_contracts in
      (match v with
      | BoolVal b -> (BoolVal (not b), multi_cfg1)
      | _ -> failwith "Type error in Not")
  | PtpEqPtp (ptp1, ptp2) ->
      (BoolVal (iota ptp1 = iota ptp2), multi_cfg)
  | GreaterThan (e1, e2) ->
      let (v1, multi_cfg1) = eval sigma iota e1 multi_cfg called_contracts in
      let (v2, multi_cfg2) = eval sigma iota e2 multi_cfg1 called_contracts in
      (match (v1, v2) with
      | IntVal i1, IntVal i2 -> (BoolVal (i1 > i2), multi_cfg2)
      | _ -> failwith "Type error in GreaterThan")
  | GreaterThanEqual (e1, e2) ->
      let (v1, multi_cfg1) = eval sigma iota e1 multi_cfg called_contracts in
      let (v2, multi_cfg2) = eval sigma iota e2 multi_cfg1 called_contracts in
      (match (v1, v2) with
      | IntVal i1, IntVal i2 -> (BoolVal (i1 >= i2), multi_cfg2)
      | _ -> failwith "Type error in GreaterThanEqual")
  | LessThan (e1, e2) ->
      let (v1, multi_cfg1) = eval sigma iota e1 multi_cfg called_contracts in
      let (v2, multi_cfg2) = eval sigma iota e2 multi_cfg1 called_contracts in
      (match (v1, v2) with
      | IntVal i1, IntVal i2 -> (BoolVal (i1 < i2), multi_cfg2)
      | _ -> failwith "Type error in LessThan")
  | LessThanEqual (e1, e2) ->
      let (v1, multi_cfg1) = eval sigma iota e1 multi_cfg called_contracts in
      let (v2, multi_cfg2) = eval sigma iota e2 multi_cfg1 called_contracts in
      (match (v1, v2) with
      | IntVal i1, IntVal i2 -> (BoolVal (i1 <= i2), multi_cfg2)
      | _ -> failwith "Type error in LessThanEqual")
  | Equal (e1, e2) ->
      let (v1, multi_cfg1) = eval sigma iota e1 multi_cfg called_contracts in
      let (v2, multi_cfg2) = eval sigma iota e2 multi_cfg1 called_contracts in
      (match (v1, v2) with
      | IntVal i1, IntVal i2 -> (BoolVal (i1 = i2), multi_cfg2)
      | _ -> failwith "Type error in Equal")
  | NotEqual (e1, e2) ->
      let (v1, multi_cfg1) = eval sigma iota e1 multi_cfg called_contracts in
      let (v2, multi_cfg2) = eval sigma iota e2 multi_cfg1 called_contracts in
      (match (v1, v2) with
      | IntVal i1, IntVal i2 -> (BoolVal (i1 <> i2), multi_cfg2)
      | _ -> failwith "Type error in NotEqual")
  | Val v -> (v, multi_cfg)
  | Self contract_name ->
    (PtpID (PID contract_name), multi_cfg)
  | PtID ptp_var -> (PtpID (iota ptp_var), multi_cfg)
  | FuncCall (func, args) ->
      let (arg_vals, multi_cfg1) = List.fold_left (fun (acc_vals, cfg) arg ->
        let (v, new_cfg) = eval sigma iota arg cfg called_contracts in
        (acc_vals @ [v], new_cfg)
      ) ([], multi_cfg) args in
      external_function_call func arg_vals sigma iota multi_cfg1 called_contracts
  | FuncCallEdamRead (edam_name, var_name) ->
      external_edam_read edam_name var_name sigma iota multi_cfg called_contracts

(* Function to evaluate function calls *)
and external_function_call func_name args sigma iota multi_cfg called_contracts =
  match (func_name, args) with
  | ("sum", [ListVal lst]) -> 
      let sum_list = List.fold_left (fun acc v -> match v with IntVal i -> acc + i | _ -> failwith "Type error in sum") 0 lst in
      (IntVal sum_list, multi_cfg)
  | ("append", [ListVal lst; ListVal elems]) -> 
      (ListVal (lst @ elems), multi_cfg)
  | ("append_lists", [StrVal lst1; StrVal lst2]) ->
    (match (sigma (Var (lst1)), sigma (Var (lst2))) with
    | (ListVal l1, ListVal l2) -> (ListVal (l1 @ l2), multi_cfg)
    | _ -> failwith "Type error in append_lists: Expected ListVal for both arguments")
  | ("length", [ListVal lst]) -> 
      (IntVal (List.length lst), multi_cfg)
  | ("initialize_list", []) ->  (* Initialize an empty list *)
      (ListVal [], multi_cfg)
  | ("initialize_map_from_key", [PtpID key; IntVal value]) ->
      (MapVal [(PtpID key, IntVal value)], multi_cfg)
  | ("initialize_empty_map", []) ->
      (MapVal [], multi_cfg)
  | ("map_update", [MapVal map; PtpID key; IntVal value]) ->
      let updated_map = (PtpID key, IntVal value) :: List.filter (fun (k, _) -> k <> PtpID key) map in
      (MapVal updated_map, multi_cfg)
  | ("initialize_map", []) ->  (* Initialize an empty map *)
      (MapVal [], multi_cfg)
  | ("update_map", [MapVal map; key; value]) ->  (* Update map with a new key-value pair *)
      let key = match key with
        | StrVal s -> StrVal s
        | BoolVal b -> BoolVal b
        | IntVal i -> IntVal i
        | PtpID p -> PtpID p
        | _ -> failwith "Invalid key type"
      in
      (MapVal (update_map map key value), multi_cfg)
  | ("update_nested_map", [MapVal map; key1; key2; value]) ->
    (MapVal (update_nested_map map key1 key2 value), multi_cfg)
  | ("min", [ListVal lst]) ->  
    let min_val = match lst with
      | [] -> 0  
      | IntVal x :: xs -> 
          List.fold_left (fun acc v ->
            match v with
            | IntVal n -> if n < acc then n else acc
            | _ -> acc  
          ) x xs
      | _ -> failwith "Unexpected value in list"  (* Fail if the list is not composed of IntVal values *)
    in
    (IntVal min_val, multi_cfg)
  | ("max", [ListVal lst]) ->  
    let max_val = match lst with
      | [] -> 0  
      | IntVal x :: xs -> 
          List.fold_left (fun acc v ->
            match v with
            | IntVal n -> if n > acc then n else acc
            | _ -> acc  
          ) x xs
      | _ -> failwith "Unexpected value in list"  (* Fail if the list is not composed of IntVal values *)
    in
    (IntVal max_val, multi_cfg)
  | ("get_amount_out", [IntVal amountIn; IntVal reserveIn; IntVal reserveOut; IntVal fee_percent]) ->  
    let multiplier = 1000 in
    let amountInWithFee = amountIn * (multiplier - fee_percent) in
    let numerator = amountInWithFee * reserveOut in
    let denominator = (reserveIn * multiplier) + amountInWithFee in
    let out_val = numerator / denominator in
    (IntVal out_val, multi_cfg)
  
  | _ -> failwith "Unknown function or type error"
and external_edam_read edam_name expresion sigma iota multi_cfg called_contracts = 
    let (edam, config) = get_edam_config edam_name multi_cfg in 
    eval config.sigma iota expresion multi_cfg called_contracts
    
(* Function to evaluate EDAM calls *)
and external_edam_write edam_name op participant_exps values_exp caller_id sigma iota multi_cfg called_contracts =
  (*Printf.printf "Calling contract -------------- %s \n\n" edam_name; *)

  (*let multi_cfg_cp = copy_multi_config multi_cfg in*)
  let (edam, config) = get_edam_config edam_name multi_cfg in
  let (values, updated_multi_cfg1) = List.fold_left (fun (acc_vals, cfg) exp ->
    let (v, new_cfg) = eval sigma iota exp cfg called_contracts in
    (acc_vals @ [v], new_cfg)
  ) ([], multi_cfg) values_exp in
  
  let (participants, updated_multi_cfg2) = List.fold_left (fun (acc_vals, cfg) exp ->
    let (v, new_cfg) = eval sigma iota exp cfg called_contracts in
    (acc_vals @ [v], new_cfg)
  ) ([], updated_multi_cfg1) participant_exps in
  
  let participants_param = List.map (function PtpID pid -> pid | _ -> failwith "Expected participant ID") participants in 
  let label_conf = (caller_id , op, participants_param, values) in
  let iota_temp = generate_iota_from_label edam_name label_conf updated_multi_cfg2 in
   (*Printf.printf "\n In the calll %s %s %s\n " 
    (string_of_pid (iota_new (Ptp "_caller"))) (string_of_op  op) 
    (String.concat " ; " (List.map (function PID id -> id) participants_param)  )
    ; *)
  let result = !perform_transition edam_name config label_conf edam iota_temp updated_multi_cfg2 called_contracts in
  let final_result = match result with
    | Some (Some(new_config), Some(new_edam), Some(updated_multi_cfg), _, _) ->
        Hashtbl.replace updated_multi_cfg.config_map edam_name new_config;
        Hashtbl.replace updated_multi_cfg.edam_map edam_name new_edam;
        (BoolVal true, updated_multi_cfg)
    | _ -> (BoolVal false, multi_cfg)
  in
  (* Printf.printf "Done -------------- %s \n\n" edam_name; *)
  final_result

(* Evaluate a list of (FuncCallEdamWrite * bool) expressions *)
let rec eval_func_write_list 
    (origin_edam_name: string)
    (func_calls: (funcCallEdamWrite * bool) list) 
    (sigma: sigma_type) 
    (iota: iota_type) 
    (multi_cfg: multi_config) 
    (called_contracts: string list)  (* Track already called EDAMs *)
  : bool * multi_config = 
  (* print_endline "Entering eval_func_write_list"; *)
  match func_calls with
  | [] -> (true, multi_cfg)  (* If there are no function calls, return success *)

  | (FuncCallEdamWrite (edam_name, operation, participant_exps, values_exp), expected_bool) :: rest ->
        let (res, updated_multi_cfg1) = 
          external_edam_write edam_name operation participant_exps values_exp (PID origin_edam_name) sigma iota multi_cfg called_contracts
        in
        (* Check if the returned value matches the expected boolean *)
        match res with
        | BoolVal actual_bool when actual_bool = expected_bool -> 
            (* Continue evaluating the rest with the updated multi_cfg *)
            eval_func_write_list origin_edam_name rest sigma iota updated_multi_cfg1 called_contracts
        | _ -> 
            (* Halt and return false with the original multi_cfg *)
            (false, multi_cfg)
     


(* Check role modes for a pair of participants *)
let check_role_modes_for_pair (role_m: role_mode_type) (role_m': role_mode_type) role_list =
  List.for_all (fun roleR ->
    let modeP = role_m roleR in
    let modeP' = role_m' roleR in
    role_modes_compatible modeP modeP'
  ) role_list

(* Helper function to recursively interleave elements from lists *)
let rec interleave prefix lists result =
  (* Base case: if all lists are empty, add the current prefix to the result *)
  if List.for_all (fun lst -> lst = []) lists then
    result := prefix :: !result  (* Update the result reference with the new prefix *)
  else
    (* Recursive case: for each list, if it's not empty, append the first element to the prefix and call the function with the rest of the list *)
    List.iteri (fun i lst ->
      match lst with
      | [] -> ()  (* If the list is empty, do nothing *)
      | hd :: tl ->  (* Otherwise, take the head and the tail of the list *)
        let new_prefix = prefix @ [hd] in  (* Append the head to the prefix *)
        let new_lists = List.mapi (fun j l -> if i = j then tl else l) lists in  (* Update the lists *)
        interleave new_prefix new_lists result  (* Recursively interleave *)
    ) lists

(* Function to shuffle and join lists *)
let shuffle_join_lists lists =
  let result = ref [] in  (* Initialize the result reference *)
  interleave [] lists result;  (* Start the interleaving process with an empty prefix *)
  !result  (* Return the final result *)

(* Helper function to remove duplicates from a list *)
let rec remove_duplicates lst =
  match lst with
  | [] -> []
  | hd :: tl -> hd :: remove_duplicates (List.filter (fun x -> x <> hd) tl)



(* Helper function to select a random element from a list *)
let random_select lst =
  let n = List.length lst in
  if n = 0 then
    None  (* Return None if the list is empty *)
  else
    let rand_index = Random.int n in
    Some (List.nth lst rand_index)  (* Return the element at the random index, wrapped in Some *)
 
(* Helper function to select a random role from a list *)
let random_select_role roles =
  match random_select roles with
  | Some role -> role
  | None -> Role "Role"


(* Helper function to generate iota mapping for a given transition *)
let generate_iota (ptp_list: ptp_var list) (participants: participant list) =
  (*Printf.printf ".................\n";
  
  Printf.printf "%s %s \n" 
  (print_participants_var_list ptp_list)
  (print_participants_list participants);
  Printf.printf ".................\n"; *)
  
  let updates = List.combine ptp_list participants in
  fun ptp_var ->
    match List.assoc_opt ptp_var updates with
    | Some participant -> participant
    | None -> PID ""

(* Helper function to parse index from a string *)
let parse_index parts =
  match parts with
  | ["int"; value] -> IntVal (int_of_string value)
  | ["str"; value] -> StrVal value
  | ["pid"; value] -> PtpID (PID value)
  | ["bool"; value] -> BoolVal (bool_of_string value)
  | _ -> failwith "Invalid index format"

(* Function to evaluate commands *)
let eval_command edam config args dependencie_map =
  (*List.iter (fun x -> Printf.printf "%s \n" x) args;*)
  match args with
  | [var_name] ->
      let value = config.sigma (Var var_name) in
      string_of_value value
  | ["sum"; var_name] ->
      let values = match config.sigma (Var var_name) with
        | ListVal lst -> List.map (function IntVal i -> i | _ -> 0) lst
        | _ -> []
      in
      let sum = List.fold_left (+) 0 values in
      string_of_int sum
  | ["count"; var_name] ->
      let count = match config.sigma (Var var_name) with
        | ListVal lst -> List.length lst
        | MapVal map -> List.length map
        | _ -> 0
      in
      string_of_int count
  | ["get"; "state"] ->
      let state_str = match config.state with State s -> s in
      state_str
  | ["countRole"; role_name] -> (
      let role = Role role_name in
      try
        (* Find the participants for the given role *)
        let participants = List.assoc role dependencie_map.participant_roles in
        string_of_int (List.length participants)
      with Not_found -> string_of_int 0 
    )
  | [var_name; "["; idx_t; idx_str; "]"] ->
      let idx = parse_index [idx_t; idx_str] in
      let value = match config.sigma (Var var_name) with
        | ListVal lst -> (match idx with IntVal i -> List.nth lst i | _ -> failwith "Invalid index type")
        | MapVal map -> List.assoc idx map
        | _ -> failwith "Invalid access"
      in
      string_of_value value
  | [var_name; "["; idx_t1; idx_str1; "]"; "["; idx_t2; idx_str2; "]"] ->
      let idx1 = parse_index [idx_t1; idx_str1] in
      let idx2 = parse_index [idx_t2; idx_str2] in
      let value = match config.sigma (Var var_name) with
        | ListVal lst -> (
            match List.nth lst (match idx1 with IntVal i -> i | _ -> failwith "Invalid index type") with
            | ListVal sublist -> List.nth sublist (match idx2 with IntVal i -> i | _ -> failwith "Invalid index type")
            | MapVal map -> List.assoc idx2 map
            | _ -> failwith "Invalid nested access"
          )
        | MapVal map -> (
            match List.assoc idx1 map with
            | ListVal sublist -> List.nth sublist (match idx2 with IntVal i -> i | _ -> failwith "Invalid index type")
            | MapVal submap -> List.assoc idx2 submap
            | _ -> failwith "Invalid nested access"
          )
        | _ -> failwith "Invalid access"
      in
      string_of_value value
  | _ -> "Invalid eval command"


(* Function to generate a random integer in a given range [low, high] *)
let generate_number_in_range low high =
  if low > high then
    failwith "Invalid range: low must be less than or equal to high"
  else
    low + Random.int (high - low + 1);;

(* Function to generate a number with a given probability *)
let generate_number_with_probability p =
  let random_value = Random.float 1.0 in
  if random_value < p then 0 else 1;;

(* Function to generate random values based on dvar_type *)
let generate_random_value (dtype: dvar_type) (v: dvar) (server_configs: server_config_type) =
  match dtype with
  | VarT "bool" -> 
      (* Generate a random boolean based on probability *)
      let random_bool = (Random.float 100.0) <= (server_configs.probability_true_for_bool *. 100.0) in
      BoolVal random_bool

  | VarT "int" -> 
      (* Generate a random integer within the specified range *)
      let random_int = generate_number_in_range server_configs.min_int_value server_configs.max_int_value in
      IntVal random_int

  | VarT "string" -> 
      (* Generate a random string with length between min_gen_string_length and max_gen_string_length *)
      let string_length = Random.int (server_configs.max_gen_string_length - server_configs.min_gen_string_length + 1) + server_configs.min_gen_string_length in
      let random_string = String.init string_length (fun _ -> Char.chr (Random.int 26 + 97)) in
      StrVal random_string

  | VarT "list_int" -> 
      (* Generate a list of random integers *)
      let list_size = Random.int server_configs.max_gen_array_size + 1 in
      let int_list = List.init list_size (fun _ -> generate_number_in_range server_configs.min_int_value server_configs.max_int_value) in
      ListVal (List.map (fun i -> IntVal i) int_list)  (* Convert the list of integers into a list of IntVal *)

  | _ -> 
      (* Fallback for unsupported types *)
      StrVal "undefined"

      
let select_valid_transition valid_data current_state dependencies_map edam_name =
  (* Extract the probabilities from the dependency map *)
  let probabilities = match Hashtbl.find_opt dependencies_map edam_name with
    | Some dependency -> dependency.transition_probabilities
    | None -> Hashtbl.create 0  (* If no probabilities are defined, return an empty hashtable *)
  in

  (* Partition transitions into those with defined probabilities and those without *)
  let with_prob, without_prob = List.partition (fun (_, _, _, _, _, _, transition, _, _, _, _) ->
    let op = match transition with (_, label, _) -> 
      let (_, _, _, _, op, _, _, _, _) = label in op
    in
    Hashtbl.mem probabilities (current_state, op)
  ) valid_data in

  (* Calculate the total probability of transitions with defined probabilities *)
  let total_defined_prob = List.fold_left (fun acc (_, _, _, _, _, _, transition, _, _, _, _) ->
    let op = match transition with (_, label, _) -> 
      let (_, _, _, _, op, _, _, _, _) = label in op
    in
    if Hashtbl.mem probabilities (current_state, op) then
      acc +. Hashtbl.find probabilities (current_state, op)
    else
      acc
  ) 0.0 with_prob in

  (* Calculate the remaining probability to be distributed *)
  let remaining_prob = 1.0 -. total_defined_prob in
  let num_without_prob = List.length without_prob in
  let mean_prob = if num_without_prob > 0 then remaining_prob /. float_of_int num_without_prob else 0.0 in

  (* Assign probabilities to all transitions (those with and without defined probabilities) *)
  let transitions_with_probs = 
    List.map (fun (label_conf, config, edam, multi_cfg, edam_name, deps_map, transition, a, b, c, d) ->
      let op = match transition with (_, label, _) -> 
        let (_, _, _, _, op, _, _, _, _) = label in op
      in
      let prob = if Hashtbl.mem probabilities (current_state, op) then
        Hashtbl.find probabilities (current_state, op)  (* Use the defined probability *)
      else
        mean_prob  (* Assign mean probability if none defined *)
      in
      (label_conf, config, edam, multi_cfg, edam_name, deps_map, transition, a, b, c, d, prob)
    ) valid_data
  in

  (* Calculate the sum of all probabilities *)
  let total_probability = List.fold_left (fun total (_, _, _, _, _, _, _, _, _, _, _, prob) -> total +. prob) 0.0 transitions_with_probs in

  (* Randomly select a transition based on cumulative probability *)
  let random_choice = Random.float total_probability in
  let rec select_transition acc_prob transitions = match transitions with
    | [] -> None  (* Shouldn't happen, but handle gracefully *)
    | (label_conf, config, edam, multi_cfg, edam_name, deps_map, transition, a, b, c, d, prob) :: rest ->
      let new_acc = acc_prob +. prob in
      if random_choice <= new_acc then
        Some (label_conf, config, edam, multi_cfg, edam_name, deps_map, transition, a, b, c, d)
      else
        select_transition new_acc rest
  in
  (* Call the recursive function to select the transition *)
  select_transition 0.0 transitions_with_probs
      

(* Get the current timestamp in human-readable format as a string, including milliseconds *)
let get_timestamp () : string =
  let current_time = Unix.gettimeofday () in  (* Get the current time with microseconds precision *)
  let tm = Unix.localtime current_time in  (* Convert to local time *)
  let milliseconds = int_of_float ((current_time -. floor current_time) *. 1000.0) in  (* Extract milliseconds *)
  (* Return the formatted timestamp as a string *)
  Printf.sprintf "%04d-%02d-%02d %02d:%02d:%02d.%03d"
    (tm.Unix.tm_year + 1900)  (* Year since 1900 *)
    (tm.Unix.tm_mon + 1)      (* Month is 0-based, so we add 1 *)
    tm.Unix.tm_mday           (* Day of the month *)
    tm.Unix.tm_hour           (* Hours *)
    tm.Unix.tm_min            (* Minutes *)
    tm.Unix.tm_sec            (* Seconds *)
    milliseconds              (* Milliseconds *)

let count_operation_occurrences log op =
  Hashtbl.fold (fun _ operations acc ->
    acc + List.fold_left (fun count (_, _, executed_op, _, _) ->
      if executed_op = op then count + 1 else count
    ) 0 operations
  ) log 0
    
let get_operations_before log op =
  Hashtbl.fold (fun _ operations acc ->
    let rec count_before lst =
      match lst with
      | [] -> acc
      | (_, _, executed_op, _, _) :: rest ->
        if executed_op = op then acc
        else count_before rest
    in
    count_before operations
  ) log 0
  
let check_operation_order log op_x op_y =
  Hashtbl.fold (fun _ operations acc ->
    let rec check_order lst has_op_y_seen =
      match lst with
      | [] -> acc && has_op_y_seen
      | (_, _, executed_op, _, _) :: rest ->
        if executed_op = op_y then check_order rest true
        else if executed_op = op_x && not has_op_y_seen then false
        else check_order rest has_op_y_seen
    in
    check_order operations false
  ) log true
  

let get_operations_by_time log =
  let all_operations = Hashtbl.fold (fun (edam_name, state) operations acc ->
    List.fold_left (fun acc (timestamp, participant, op, participants, dvars) ->
      (timestamp, edam_name, state, participant, op, participants, dvars) :: acc
    ) acc operations
  ) log [] in
  List.sort (fun (ts1, _, _, _, _, _, _) (ts2, _, _, _, _, _, _) -> compare ts1 ts2) all_operations
  
let get_participants_for_operation log edam_name op =
  Hashtbl.fold (fun (log_edam_name, _) operations acc ->
    if log_edam_name = edam_name then
      List.fold_left (fun acc (_, _, executed_op, participants, _) ->
        if executed_op = op then participants @ acc else acc
      ) acc operations
    else acc
  ) log []

let get_variables_for_operation log edam_name op =
  Hashtbl.fold (fun (log_edam_name, _) operations acc ->
    if log_edam_name = edam_name then
      List.fold_left (fun acc (_, _, executed_op, _, dvars) ->
        if executed_op = op then dvars @ acc else acc
      ) acc operations
    else acc
  ) log []
  
let has_completed_state log edam_name state =
  Hashtbl.fold (fun (log_edam_name, log_state) operations acc ->
    if log_edam_name = edam_name && log_state = state then true else acc
  ) log false
  

let get_participant_operations log participant =
  Hashtbl.fold (fun _ operations acc ->
    List.fold_left (fun acc (_, _, op, participants, _) ->
      if List.exists (fun p -> p = participant) participants then op :: acc else acc
    ) acc operations
  ) log []
  
let is_in_final_state server_configs edam_name =
  match Hashtbl.find_opt server_configs.config_map edam_name with
  | Some config -> (
      let edam = find_with_debug server_configs.edam_map edam_name in
      List.exists (fun final_state -> final_state = config.state) edam.final_modes
    )
  | None -> false
  