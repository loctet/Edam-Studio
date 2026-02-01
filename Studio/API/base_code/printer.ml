open Types

(* Helper function to check if a variable is in sigma *)
let sigma_contains (sigma : sigma_type) (v : dvar) : bool =
  try
    ignore (sigma v); true
  with
  | _ -> false

(* Function to convert value_type to string for printing *)
let rec string_of_value = function
  | IntVal i -> string_of_int i
  | BoolVal b -> string_of_bool b
  | StrVal s -> s
  | PtpID (PID p) -> p
  | ListVal lst -> "[" ^ (String.concat "; " (List.map string_of_value lst)) ^ "]"
  | MapVal map -> "{" ^ (String.concat "; " (List.map (fun (k, v) -> string_of_value k ^ ": " ^ string_of_value v) map)) ^ "}"

  
(* Function to concatenate a list of participant IDs into a single string *)
let print_participants_list (participants: participant list) : string =
  let rec aux acc = function
    | [] -> acc
    | PID id :: rest -> aux (acc ^ " " ^ id) rest
  in
  aux "" participants

let print_roles_list_only_on_participant (roles: role_type list) =
  Printf.printf "    Roles: %s\n" (String.concat " " (List.map (function Role r -> r) roles))

let print_roles_list config participants =
  let { pi = pi; } = config in
  List.iter (fun participant ->
    let () = print_endline "    -----------------" in
    let roles = pi participant in
    match participant with
    | PID pid -> 
      Printf.printf "    Participant: %s, Roles: %s\n" pid (String.concat ", " (List.map (function Role r -> r) roles))
  ) participants



(* Print participants and their roles *)
let print_participants_and_roles (config: configuration) (iota: iota_type) (ptp_vars: ptp_var list) =
  let { pi; _ } = config in
  let () = print_endline "" in
  let participants = List.fold_left (fun acc ptp_var ->
    let participant = iota ptp_var in
    if List.exists (fun p -> p = participant) acc then acc else participant :: acc
  ) [] ptp_vars in
  List.iter (fun participant ->
    let () = print_endline "    -----------------" in
    let roles = pi participant in
    match participant with
    | PID pid -> 
      Printf.printf "    Participant: %s, Roles: %s\n"
        pid
        (String.concat ", " (List.map (function Role r -> r) roles))
  ) participants



(* Function to print the contents of a map *)
let rec print_map map =
  Printf.printf "{\n        ";
  List.iter (fun (k, v) ->
    let key_str = match k with
      | StrVal s -> s
      | BoolVal b -> string_of_bool b
      | IntVal i -> string_of_int i
      | PtpID (PID p) -> p
      | _ -> "complex_key"
    in
    match v with
    | IntVal i -> Printf.printf "%s: %d; " key_str i
    | StrVal s -> Printf.printf "%s: \"%s\"; " key_str s
    | BoolVal b -> Printf.printf "%s: %b; " key_str b
    | PtpID (PID p) -> Printf.printf "%s: %s; " key_str p
    | MapVal m -> Printf.printf "%s: " key_str; print_map m
    | ListVal lst -> 
        Printf.printf "%s: [" key_str;
        List.iter (fun e -> match e with
          | IntVal i -> Printf.printf "%d " i
          | StrVal s -> Printf.printf "\"%s\" " s
          | BoolVal b -> Printf.printf "%b " b
          | PtpID (PID p) -> Printf.printf "%s " p
          | _ -> Printf.printf "complex_val ") lst;
        Printf.printf "]; ") map;
  Printf.printf "    }\n"
  
(* Function to print the contents of sigma *)
let print_sigma (sigma: sigma_type) (vars: dvar list) : unit =
  Printf.printf "\n Sigma : \n\n";
  List.iter (fun (Var v) ->
    let dvar = Var v in
    if sigma_contains sigma dvar then
      match sigma dvar with
      | BoolVal b -> Printf.printf "    %s: %b\n" v b
      | IntVal i -> Printf.printf "    %s: %d\n" v i
      | StrVal s -> Printf.printf "    %s: %s\n" v s
      | PtpID (PID p) -> Printf.printf "    %s: %s\n" v p
      | ListVal lst -> 
          Printf.printf "    %s: [" v;
          List.iter (fun e -> match e with
            | IntVal i -> Printf.printf "%d " i
            | StrVal s -> Printf.printf "\"%s\" " s
            | BoolVal b -> Printf.printf "%b " b
            | PtpID (PID p) -> Printf.printf "%s " p
            | _ -> Printf.printf "complex_val ") lst;
          Printf.printf "]\n"
      | MapVal map -> 
          Printf.printf "    %s: " v; 
          print_map map
    else
      Printf.printf "    %s: not found in sigma\n" v
  ) vars


let print_all_sigmas (multi_cfg:multi_config) = 
  Hashtbl.iter (fun edam_name config -> 
    let edam = Hashtbl.find multi_cfg.edam_map edam_name in
    Printf.printf "\nEdam Name: %s\n" edam_name;
    print_sigma config.sigma edam.variables_list;
  ) multi_cfg.config_map

let print_list l = 
  Printf.printf "[";
  List.iter (fun x -> Printf.printf "%s " x) l;
  Printf.printf "]\n"

let print_list_list l = 
  List.iter print_list l

(* Print details of a transition *)
let print_transition_details (transition: transition_type) (iota: iota_type) (sigma: sigma_type) (mark: string) =
  let (q_from, (guard, rho, ptp, op, ptp_list, dvar_list, assign_list, rho', name), q_to) = transition in
  let state_from = match q_from with State s -> s in
  let state_to = match q_to with State s -> s in
  let op_str = match op with Operation o -> o in
  let ptp_str = match ptp with Ptp p -> iota (Ptp p) |> function PID id -> id in
  let ptp_list_str = String.concat ", " (List.map (fun (Ptp p) -> iota (Ptp p) |> function PID id -> id) ptp_list) in

  (* Map dvar_list to extract the dvar and print its value from sigma *)
  let dvar_list_str = 
    String.concat ", " 
      (List.map (fun (_, Var v) -> 
         let value = sigma (Var v) in 
         Printf.sprintf "%s: %s" v (string_of_value value)  
       ) dvar_list)
  in

  Printf.printf "  ➖ (%s) %s %s %s(dvars: [%s], participants: [%s]) -> %s %s\n" 
    name
    state_from
    ptp_str
    op_str
    dvar_list_str
    ptp_list_str
    state_to
    mark

(* Print details of a transition *)
let print_transition_details_failled (transition: transition_type) (iota: iota_type) dvar_list (mark: string) =
  let (q_from, (guard, rho, ptp, op, ptp_list, _, assign_list, rho', name), q_to) = transition in
  let state_from = match q_from with State s -> s in
  let state_to = match q_to with State s -> s in
  let op_str = match op with Operation o -> o in
  let ptp_str = match ptp with Ptp p -> iota (Ptp p) |> function PID id -> id in
  let ptp_list_str = String.concat ", " (List.map (fun (Ptp p) -> iota (Ptp p) |> function PID id -> id) ptp_list) in

  (* Map dvar_list to extract the dvar and print its value from sigma *)
  let dvar_list_str = 
    String.concat ", " 
      (List.map (fun (v) -> 
         Printf.sprintf "%s" (string_of_value v)  
       ) dvar_list)
  in

  Printf.printf "  ➖ (%s) %s %s %s(dvars: [%s], participants: [%s]) -> %s %s\n" 
    name
    state_from
    ptp_str
    op_str
    dvar_list_str
    ptp_list_str
    state_to
    mark

(* Function to print a symbolic trace *)
let print_symbolic_trace symbolic_trace trace_number =
  Printf.printf "\n=== Symbolic Trace #%d ===\n" trace_number;
  List.iteri (fun idx (edam_name, (ptp, Operation op, ptp_list, dvar_list), iota, (state_from, label, state_to)) ->
    (* Extract state names *)
    let state_from_str = match state_from with State s -> s in
    let state_to_str = match state_to with State s -> s in
    
    (* Extract participant names *)
    let ptp_str = match ptp with Ptp p -> p in
    let ptp_list_str = 
      String.concat ", " (List.map (fun (Ptp p) -> p) ptp_list)
    in
    
    (* Extract variable assignments *)
    let dvar_list_str = 
      String.concat ", " (List.map (fun (_, Var v) -> v) dvar_list)
    in

    let list_of_params =
      [ptp_list_str; dvar_list_str]
      |> List.filter (fun s -> s <> "")
      |> String.concat ", "
    in

    Printf.printf "Step #%d_%s: %s -- %s %s(%s) -> %s  \n" 
    (idx + 1) edam_name ptp_str state_from_str op list_of_params state_to_str
  ) symbolic_trace;
  Printf.printf "=== End of Trace ===\n"


(* Print a trace *)
let print_trace trace =
  Printf.printf "\n\nTrace:\n";
  List.iter (fun (contract, (participant, operation, participants, values), expected_result, _,_, _, _) ->
    (* Convert values to string *)
    let values_str = String.concat ", " (List.map (function
      | StrVal s -> Printf.sprintf "\"%s\"" s
      | IntVal v -> string_of_int v
      | BoolVal b -> string_of_bool b
      | PtpID (PID p) -> p
      | ListVal lst -> 
          "[" ^ (String.concat "; " (List.map (function
            | StrVal s -> Printf.sprintf "\"%s\"" s
            | IntVal v -> string_of_int v
            | BoolVal b -> string_of_bool b
            | PtpID (PID p) -> p
            | _ -> "complex_val"
          ) lst)) ^ "]"
      | MapVal map ->
          "{" ^ (String.concat "; " (List.map (fun (k, v) ->
            let key_str = match k with
              | StrVal s -> s
              | BoolVal b -> string_of_bool b
              | IntVal i -> string_of_int i
              | PtpID (PID p) -> p
              | _ -> "complex_key"
            in
            let val_str = match v with
              | StrVal s -> Printf.sprintf "\"%s\"" s
              | IntVal i -> string_of_int i
              | BoolVal b -> string_of_bool b
              | PtpID (PID p) -> p
              | _ -> "complex_val"
            in
            key_str ^ ": " ^ val_str
          ) map)) ^ "}"
    ) values) in

    (* Convert participants to string *)
    let participants_str = String.concat ", " (List.map (function PID id -> id) participants) in
    let expected_result_str = match expected_result with
      | true -> "✅"
      | false -> "❌"
    in
    (* Print each trace line *)
    Printf.printf "   ➖ Contract(%s) %s: %s([%s], [%s]) => %s\n"
      contract
      (match participant with PID s -> s)
      (match operation with Operation s -> s)
      participants_str
      values_str
      expected_result_str
      
  ) trace;

  (* Printf.printf "\nExecution:\n\n" *)
  Printf.printf "\n\n"


