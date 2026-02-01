open Types
open Helper
open Core_functions
open Printer


(* Function to update the list of roles in dependencies based on the config's pi *)
let update_participant_roles_in_dependancy 
  (ptp_vars: ptp_var list) 
  (participants: participant list)  
  (config: configuration) 
  (dependencies: dependancy_type) 
  : dependancy_type =

  (* Helper function to update roles for a single participant *)
  let update_roles_for_participant (ptp_var: ptp_var) (participant: participant) (deps: dependancy_type) =
    let roles = config.pi participant in
    List.fold_left (fun updated_deps role ->
      match List.assoc_opt role updated_deps.participant_roles with
      | Some existing_participants ->
          if List.mem participant existing_participants then
            updated_deps  
          else
            (* Add participant to the existing role *)
            let new_roles = (role, participant :: existing_participants) :: 
                            List.remove_assoc role updated_deps.participant_roles in
            { updated_deps with participant_roles = new_roles }
      | None ->
          (* Role doesn't exist, create a new entry for it *)
          let new_roles = (role, [participant]) :: updated_deps.participant_roles in
          { updated_deps with participant_roles = new_roles }
    ) deps roles
  in

  (* Iterate over the list of ptp_vars and participants, updating roles for each *)
  List.fold_left2 (fun updated_deps ptp_var participant ->
    update_roles_for_participant ptp_var participant updated_deps
  ) dependencies ptp_vars participants
  

(* Helper function to generate a new participant *)
let generate_new_participant role existing_participants updated_dependencies (server_configs: server_config_type) =
  let new_participant = PID (role ^ string_of_int ((List.length existing_participants) + 1)) in
  let new_roles = (Role role, new_participant :: existing_participants) :: List.remove_assoc (Role role) updated_dependencies.participant_roles in
  (new_participant, { updated_dependencies with participant_roles = new_roles })

(* Helper function to select an existing participant or generate a new one based on server configuration *)
let select_or_generate_participant role existing_participants updated_dependencies can_generate (server_configs: server_config_type) =
  if can_generate && Random.float 1.0 <= server_configs.probability_new_participant then
    (* Generate a new participant if allowed and decided based on probability *)
    generate_new_participant role existing_participants updated_dependencies server_configs
  else
    (* Select an existing participant if available, otherwise generate a new one *)
    match random_select existing_participants with
    | Some participant -> (participant, updated_dependencies)
    | None -> generate_new_participant role existing_participants updated_dependencies server_configs


(* Function to get the role for a participant based on the EDAM's roles and the transition's rho mapping *)
let get_role (user: string) (rho: role_a_type) (edam:edam_type) : string =
  let possible_top_roles = 
    List.fold_left (fun acc (r) ->
      match rho (Ptp user) r with
      | Top  -> r :: acc 
      | _ -> acc 
    ) [] edam.roles_list
  in 
  let possible_non_top_roles = 
    List.fold_left (fun acc (r) ->
      match rho (Ptp user) r with
      | Top  -> acc 
      | _ -> r :: acc 
    ) [] edam.roles_list
  in   
  match possible_top_roles with
  | [] -> (
      let selected_role = random_select possible_non_top_roles in
      match selected_role with
      | Some (Role r) -> r  
      | _ -> user  
    )  
  | _ -> 
      let selected_role = random_select possible_top_roles in
      match selected_role with
      | Some (Role r) -> r  
      | _ -> user  

(* Retrieve participants based on roles and server configuration *)
let getParticipantsIds 
  (edam: edam_type)
  (label_transition: label_type)
  (ptp_list: ptp_var list)
  (dependencies: dependencies_map)
  (current_state: state_type)
  (op: operation) 
  (server_configs: server_config_type) 
  (for_vars: bool) : (participant list * dependencies_map) =
  let (_, pi, _, _, _, _, _, _, _) = label_transition in
  
  (* Helper function to collect all existing participants across all roles and dependencies, ensuring no duplicates *)
  let gather_existing_participants dependencies_map =
    Hashtbl.fold (fun _ dependancy acc ->
      List.fold_left (fun acc (role, participants) ->
        List.fold_left (fun acc participant ->
          if List.mem participant acc then acc  
          else participant :: acc  
        ) acc participants
      ) acc dependancy.participant_roles
    ) dependencies_map [] 
  in

  (* Gather all existing participants from the entire dependencies map *)
  let all_existing_participants = gather_existing_participants dependencies in

  (*
  Printf.printf "\n\nList for selection ";
  List.iter(fun (id) -> match id with PID p -> Printf.printf "%s, " p) all_existing_participants ;
  Printf.printf "\n\n----------\n";
  *)

  List.fold_right (fun (Ptp user) (acc_participants, dependencies_map) ->
    let updated_dependencies = find_with_debug dependencies edam.name in
    let role = get_role user pi edam in
    if List.length all_existing_participants > 0 then
        (* Role exists in dependencies, check if it can generate a new participant *)
        let can_generate = 
          if not for_vars then 
            (  
              List.exists (fun (state, operation, can_generate) ->
                state = current_state && operation = op && can_generate
              ) updated_dependencies.can_generate_participants
            ) || ((List.length updated_dependencies.can_generate_participants) = 0 )
          else 
            (List.exists (fun (state, operation, can_generate) ->
              state = current_state && operation = op && can_generate
            ) updated_dependencies.can_generate_participants_vars) || ((List.length updated_dependencies.can_generate_participants_vars) = 0 )
        in
        (* Select or generate participant based on whether it's allowed to generate *)
        let participant, new_dependencies = select_or_generate_participant role all_existing_participants updated_dependencies can_generate server_configs in
        Hashtbl.replace dependencies edam.name new_dependencies;
        (participant :: acc_participants, dependencies)  
    else 
        (* Role does not exist in dependencies, generate a new participant *)
        let new_participant, new_dependencies = generate_new_participant role [] updated_dependencies server_configs in
        Hashtbl.replace dependencies edam.name new_dependencies;
        (new_participant :: acc_participants, dependencies)  
  ) ptp_list ([], dependencies)


  
(* Function to find participants for a given ptp *)  
let find_participants_for_ptp 
    (pi: pi_type) 
    (rho: role_a_type) 
    (ptp: ptp_var) 
    (participants: participant list) 
    (roles: role_type list) 
  : participant list =
  (* Extract roles marked as Top or Bottom in the given ptp's rho *)
  let rho_a = rho ptp in
  let top_roles, bottom_roles =
    List.fold_left (fun (tops, bottoms) role ->
      match rho_a role with
      | Top -> (role :: tops, bottoms)
      | Bottom -> (tops, role :: bottoms)
      | Unknown -> (tops, bottoms)  (* Ignore Unknown for this step *)
    ) ([], []) roles
  in
  (* Filter participants whose roles match the requirements *)
  List.filter (fun participant ->
    let participant_roles = pi participant in
    (* Check if the participant has all Top roles and none of the Bottom roles *)
    List.for_all (fun role -> List.mem role participant_roles) top_roles &&
    List.for_all (fun role -> not (List.mem role participant_roles)) bottom_roles
  ) participants

(* function for getOrGenParticipantsIds *)
let getOrGenParticipantsIds
    (server_configs: server_config_type)
    (existing_participants: participant list)
    (ptp_list: ptp_var list)
    (multi_cfg: multi_config)
    (for_params: bool)
    (current_edam_name: string)
    (rho: role_a_type)
    (should_only_right:bool)
  : (participant list * participant list) =

  (* Retrieve pi and roles from the current edam *)
  let current_edam = find_with_debug multi_cfg.edam_map current_edam_name in
  let current_config = find_with_debug multi_cfg.config_map current_edam_name in
  let pi = current_config.pi in
  let roles = current_edam.roles_list in

  (* Initialize the result lists *)
  let list_of_par = ref [] in
  let list_of_new = ref [] in

  (* Combine the existing participants with edam names if for_params is true *)
  let valid_participants =
    if for_params then
      Hashtbl.fold (fun edam_name _ acc ->
        if edam_name <> current_edam_name then
          acc @ [PID edam_name]
        else
          acc
      ) multi_cfg.edam_map existing_participants
    else
      existing_participants
  in

  (* Process each ptp in ptp_list *)
  List.iter (fun ptp ->
    (* Find eligible participants using find_participants_for_ptp *)
    let eligible_participants = find_participants_for_ptp pi rho ptp valid_participants roles in
    let ineligible_participants = List.filter (fun participant -> not (List.mem participant eligible_participants)) valid_participants in
   
    (* Printf.printf "eligible_participants : %s ineligible_participants: %s \n" 
      (Printer.print_participants_list eligible_participants)
      (Printer.print_participants_list ineligible_participants);
    
    Printer.print_roles_list current_config ineligible_participants ; *)
    (* Check if we should generate a new participant *)
    if (should_only_right && (List.length eligible_participants) > 0) then 
      (* Randomly select from eligible participants *)
      let selected_participant =
        List.nth eligible_participants (Random.int (List.length eligible_participants))
      in
      list_of_par := selected_participant :: !list_of_par;
    else (
      if (Random.float 1.0 <= server_configs.probability_new_participant || valid_participants = []) then
        (* Generate a new participant if no eligible participant exists or based on probability *)
        let new_participant = PID ("_" ^ string_of_int (List.length existing_participants + List.length !list_of_new)) in
        list_of_par := new_participant :: !list_of_par;
        list_of_new := new_participant :: !list_of_new;
      else 
        if Random.float 1.0 >= server_configs.probability_right_participant && (List.length eligible_participants) > 0 then 
          (* Randomly select from eligible participants *)
          let selected_participant =
            List.nth eligible_participants (Random.int (List.length eligible_participants))
          in
          list_of_par := selected_participant :: !list_of_par;
        else 
          if ineligible_participants = [] && eligible_participants = [] then
            let new_participant = PID ("_" ^ string_of_int (List.length existing_participants + List.length !list_of_new)) in
            list_of_par := new_participant :: !list_of_par;
            list_of_new := new_participant :: !list_of_new;
          else 
            let merged_list = ineligible_participants @ eligible_participants in
            let selected_participant =
              List.nth merged_list (Random.int (List.length merged_list))
            in
            list_of_par := selected_participant :: !list_of_par;
    )
  ) ptp_list;

  (* Return the result lists *)
  (!list_of_par, !list_of_new)
  

(* Generate a random trace by first creating symbolic traces, and then generating real traces from them *)
let generate_random_trace 
    (multi_cfg: multi_config) 
    (dependencies_map: dependencies_map) 
    (server_configs: server_config_type)
    (max_trace_size: int) 
    (real_traces_per_symbolic: int) 
    (trace_number : int) =
  
  (* Helper function to simulate a single symbolic transition for a specific EDAM *)
  let simulate_single_symbolic_transition 
      (edam_name: string)
      (current_multi_cfg: multi_config) 
      (current_trace: (string * (ptp_var * operation * (ptp_var list) * ((dvar_type * dvar) list)) * iota_type * transition_type) list) : 
        (string * (ptp_var * operation* (ptp_var list) * ((dvar_type * dvar) list) ) * iota_type * transition_type) list =

    let edam = find_with_debug current_multi_cfg.edam_map edam_name in
    let config = find_with_debug current_multi_cfg.config_map edam_name in

    (* Get all possible transitions from the current state *)
    let current_state = config.state in
    let possible_transitions = List.filter (fun (q, _, _) -> q = current_state) edam.transitions in

    match random_select possible_transitions with
    | None -> current_trace (* No transitions possible *)
    | Some (q, label, q_to) ->
      let (_, _, ptp, op, ptp_list, dvar_list, _, _, _) = label in

      (* Construct a symbolic label configuration *)
      let label_conf = (ptp, op, ptp_list, dvar_list) in
      let iota_placeholder = generate_iota [] [] in

      (* Add the symbolic transition to the trace *)
      let updated_trace = current_trace @ [(edam_name, label_conf, iota_placeholder, (q, label, q_to))] in

      (* Update the configuration to reflect the new state *)
      let new_config = { config with state = q_to } in
      Hashtbl.replace current_multi_cfg.config_map edam_name new_config;

      updated_trace
  in

  (* Initialize symbolic transitions for each EDAM *)
  let initialize_symbolic_transitions multi_cfg =
    Hashtbl.fold (fun edam_name _ acc ->
      simulate_single_symbolic_transition edam_name multi_cfg acc
    ) multi_cfg.edam_map []
  in

  (* Simulate additional symbolic transitions *)
  let rec simulate_symbolic_transitions 
      (current_multi_cfg: multi_config) 
      (current_trace: (string * (ptp_var * operation * (ptp_var list) * ((dvar_type * dvar) list)) * iota_type * transition_type) list) 
      (remaining_steps: int) : (string * (ptp_var * operation * (ptp_var list) * ((dvar_type * dvar) list)) * iota_type * transition_type) list =

    if remaining_steps = 0 then current_trace else
      (* Select a random EDAM from the multi-config *)
      let edam_list = Hashtbl.fold (fun key _ acc -> key :: acc) current_multi_cfg.edam_map [] in
      match random_select edam_list with
      | None -> current_trace (* No EDAM to select *)
      | Some edam_name ->
        simulate_single_symbolic_transition edam_name current_multi_cfg current_trace
        |> fun updated_trace -> simulate_symbolic_transitions current_multi_cfg updated_trace (remaining_steps - 1)

  in
  
  (* Generate real traces from a symbolic trace *)
  let generate_real_traces_from_symbolic 
      (multi_cfg: multi_config) 
      (symbolic_trace: (string * (ptp_var * operation * (ptp_var list) * ((dvar_type * dvar) list)) * iota_type * transition_type) list) 
      (server_configs: server_config_type) 
      (real_trace_count: int) : ((string * label_conf) list) list =
      
    
    let rec generate_real_trace copy_multi_cfg symbolic_step_list acc _list_of_par num_of_calls =
      match symbolic_step_list with
      | [] -> List.rev acc
      | a_call :: rest ->
      let (edam_name, (ptp, Operation op, ptp_list, dvar_list), _, (_,((guard,list_of_calls), pi, _,_,_,_,_,_,_),_)) = a_call in

        (* Printf.printf "\n\nFirst eval of the trace  \n\n"; *)
        let new_copy_of_multi_cfg1 = (copy_multi_config copy_multi_cfg) in 
        let (result_1, new_copy_of_multi_cfg) = evaluate_trace acc  new_copy_of_multi_cfg1 in

        (* Helper.print_trace result_1; *)
        let config = find_with_debug new_copy_of_multi_cfg.config_map edam_name in
        let shoul_only_right = (num_of_calls =  server_configs.max_fail_try) in 
       (*  Printf.printf "Added and now run Trace Op: %s : %b \n" op shoul_only_right;  *)
        let ptp_id, new_participants = getOrGenParticipantsIds server_configs !_list_of_par [ptp] new_copy_of_multi_cfg false edam_name pi shoul_only_right in
        _list_of_par := new_participants @ !_list_of_par;
        let participants, new_participants = getOrGenParticipantsIds server_configs !_list_of_par ptp_list new_copy_of_multi_cfg true edam_name pi shoul_only_right in
        _list_of_par := new_participants @ !_list_of_par;
        let iota_updated = generate_iota ((Ptp edam_name) :: (ptp :: ptp_list)) ((PID edam_name):: (ptp_id @ participants)) in
        let ctx = Z3.mk_context [] in
        
        (* || edam_name = "AMM" || edam_name = "Token1" || edam_name = "Token2" *)
        let real_values = if not shoul_only_right then (
          List.map (fun (dtype, dvar) ->
            Helper.generate_random_value dtype dvar server_configs
          ) dvar_list
        ) else (
          (* Check if the guard is satisfiable using Z3 *)
          (* Printf.printf "\n Op: %s \n" op; *)
          let guard_satisfied, model_bindings = Z3_module.check_guard_satisfiability ctx guard dvar_list config.sigma iota_updated new_copy_of_multi_cfg in
          (*Printf.printf "Guard satisfied: %b\n" (guard_satisfied = Z3.Solver.SATISFIABLE);*)
          if guard_satisfied != Z3.Solver.SATISFIABLE then (
            List.map (fun (dtype, dvar) ->
              Helper.generate_random_value dtype dvar server_configs
            ) dvar_list
          ) else (
            List.map (fun (dtype, dvar) ->
              match dvar with
              | Var v -> (
                  match List.assoc_opt v model_bindings with
                  | Some z3_val ->
                      if Z3.Boolean.is_bool z3_val then
                        BoolVal (Z3.Boolean.is_true z3_val)
                      else if Z3.Arithmetic.is_int z3_val then
                        IntVal (int_of_string (Z3.Arithmetic.Integer.numeral_to_string z3_val))
                      else
                        StrVal (Z3.Expr.to_string z3_val)
                  | None ->
                      (*Printf.printf "Generating random value for dvar: %s\n" v;*)
                      Helper.generate_random_value dtype dvar server_configs
                )
            ) dvar_list
          )
         
        ) in
        let real_label_conf = (iota_updated ptp, Operation op, participants, real_values) in 
        let current_trace = acc @ [(edam_name, real_label_conf)] in
        let result = evaluate_trace_last [(edam_name, real_label_conf)] result_1 new_copy_of_multi_cfg in
        (* Helper.print_trace result; *)
        let (_, _, success, _, _, _,_)= (List.nth result (List.length result - 1)) in 
        (* Printf.printf "Ended run Trace Op: %s: %b \n" op success; *)
        if List.length result > 0 && not success && (num_of_calls < server_configs.max_fail_try) then
          generate_real_trace copy_multi_cfg (a_call :: rest) current_trace _list_of_par (num_of_calls + 1)
        else
          generate_real_trace copy_multi_cfg rest current_trace _list_of_par 0
    in

    (* Generate multiple real traces *)
    List.init real_trace_count (fun _ ->
      (* Printf.printf "\n\n New Trace \n\n"; *)
      let _list_of_par = ref [] in (* Initialize for each trace *)
      let copy_multi_cfg = copy_multi_config multi_cfg in  
      generate_real_trace copy_multi_cfg symbolic_trace [] _list_of_par 0
    ) in

  (* Generate symbolic trace *)
  let symbolic_trace =
    let copy_multi_cfg = copy_multi_config multi_cfg in 
    let initialized_trace = initialize_symbolic_transitions copy_multi_cfg in
    simulate_symbolic_transitions copy_multi_cfg initialized_trace max_trace_size
  in
  (* Generate real traces from the symbolic trace *)
  (symbolic_trace, (generate_real_traces_from_symbolic multi_cfg symbolic_trace server_configs real_traces_per_symbolic)) 


(* Generate tests for pi mapping and roles *)
let generate_pi_tests 
(test_code: Buffer.t) 
(rho: role_a_type) 
(iota: iota_type) 
(roles: role_type list) 
(ptp_list: ptp_var list) 
(instance_name: string) =
  let sorted_roles_list = sort_roles roles in
  (* Helper function to map a ptp to the corresponding variable in the test *)
  let get_ptp_id ptp =
    match iota ptp with
    | PID id -> Printf.sprintf "participant_%s" id
  in

  (* Generate tests for each ptp and role *)
  List.iter (fun ptp ->
    let ptp_var = get_ptp_id ptp in
    List.iter (fun role ->
      let role_var = match role with Role r -> Printf.sprintf "Roles.%s" r in
      let int_role_var = get_roles_index role sorted_roles_list in
      match rho ptp role with
      | Top ->
          (* Test for Top case: expect _permissions[ptp][role] to be true *)
          Buffer.add_string test_code (Printf.sprintf "    // Verify Top role for %s and %s\n" ptp_var role_var);
          Buffer.add_string test_code (Printf.sprintf "    expect(await %s._permissions(%s, %d)).to.equal(true);\n" instance_name ptp_var int_role_var);
      | Bottom ->
          (* Test for Bottom case: expect _permissions[ptp][role] to be false *)
          Buffer.add_string test_code (Printf.sprintf "    // Verify Bottom role for %s and %s\n" ptp_var role_var);
          Buffer.add_string test_code (Printf.sprintf "    expect(await %s._permissions(%s, %d)).to.equal(false);\n" instance_name ptp_var int_role_var);
      | Unknown ->
          (* Test for Unknown case: log that no check is made *)
          Buffer.add_string test_code (Printf.sprintf "");
    ) roles
  ) ptp_list

(************)

let get_params_str data_params deployed_addresses =  String.concat ", " (List.map (function
      | IntVal i -> string_of_int i
      | BoolVal b -> string_of_bool b
      | StrVal s -> Printf.sprintf "\"%s\"" s
      | ListVal l ->
          let list_items = List.map (function
            | IntVal i -> string_of_int i
            | BoolVal b -> string_of_bool b
            | StrVal s -> Printf.sprintf "\"%s\"" s
            | _ -> "unknown"
          ) l in
          Printf.sprintf "[%s]" (String.concat ", " list_items)
      | PtpID (PID id) ->
          if Hashtbl.mem deployed_addresses id then
            Printf.sprintf "instance_%s.address" id
          else
            Printf.sprintf "accounts[%s]" id
      | _ -> "unknown"
    ) data_params)
    

(* Helper function to extract dependencies from an expression 
let rec extract_dependencies_from_exp exp =
  match exp with
  | FuncCallEdamRead (target_edam, _) 
  | FuncCallEdamWrite (target_edam, _, _, _, _) ->
      [target_edam]
  | Plus (e1, e2) | Minus (e1, e2) | Times (e1, e2) | Divide (e1, e2) 
  | And (e1, e2) | Or (e1, e2) | GreaterThan (e1, e2) | GreaterThanEqual (e1, e2)
  | LessThan (e1, e2) | LessThanEqual (e1, e2) | Equal (e1, e2) ->
      (extract_dependencies_from_exp e1) @ (extract_dependencies_from_exp e2)
  | Not e -> extract_dependencies_from_exp e
  | ListIndex (e1, e2, e3) | MapIndex (e1, e2, e3) ->
      (extract_dependencies_from_exp e1) @ (extract_dependencies_from_exp e2) @ (extract_dependencies_from_exp e3)
  | Val _ | Dvar _ | Pvar_a _ | PtID _ -> []
  | FuncCall (_, args) -> List.flatten (List.map extract_dependencies_from_exp args)
  | _ -> failwith ("exp Erroer ")
*)

(* Helper function to extract dependencies from a transition *)
let extract_dependencies_from_transition (_, ((_, list_of_calls), _, _, _, _, _, _, _, _), _) =
  List.map (fun (FuncCallEdamWrite (target_edam, _, _, _), _) -> target_edam) list_of_calls


(* Function to compute the deployment order and parameters for EDAMs *)
let compute_edam_deployment_order config_map =
  (* Helper to collect dependencies for a single EDAM *)
  let collect_dependencies edam =
    let dependencies = ref [] in
    List.iter (fun transition ->
      let transition_deps = extract_dependencies_from_transition transition in
      dependencies := !dependencies @ transition_deps
    ) edam.transitions;
    List.sort_uniq compare !dependencies
  in
  (* Topological sort to build deployment order *)
  let deployment_order = ref [] in
  let visited = Hashtbl.create (Hashtbl.length config_map) in

  (* Recursive helper to visit a EDAM and its dependencies *)
  let rec visit edam_name =
    if not (Hashtbl.mem visited edam_name) then (
      Hashtbl.add visited edam_name true;
      let edam = find_with_debug config_map edam_name in
      let dependencies = collect_dependencies edam in
      List.iter visit dependencies;
      deployment_order := !deployment_order @ [edam_name]
    )
  in

  (* Iterate over all EDAMs in the config map *)
  Hashtbl.iter (fun edam_name _ -> visit edam_name) config_map;

  (* Build deployment info *)
  let deployment_info_list = List.map (fun edam_name ->
    let edam = find_with_debug config_map edam_name in
    let dependencies = collect_dependencies edam in
    { edam_name; params = dependencies }
  ) !deployment_order in

  deployment_info_list


(* Function to generate deployment logic for a trace *)
let generate_deployment_logic trace deployment_order =
  (* A hash table to store deployed instance names for quick lookup *)
  let deployed_instances = Hashtbl.create 10 in

  (* Helper to resolve parameters dynamically *)
  let resolve_params data_params participants deployed_instances =
    let participants_str = String.concat ", " (List.map (function
      | PID id -> Printf.sprintf "participant_%s" id
    ) participants) in
    let params_str = get_params_str data_params deployed_instances in
    String.concat ", " (List.filter ((<>) "") [participants_str; params_str])
  in

  (* Helper to generate deployment code for a single EDAM *)
  let deploy_edam edam_name params =
    let instance_name = Printf.sprintf "instance_%s" edam_name in
    let param_str = String.concat ", " params in
    let deployment_code =
      Printf.sprintf "    const %s = await %s.new(%s);\n" instance_name edam_name param_str
    in
    Hashtbl.add deployed_instances edam_name instance_name;
    deployment_code
  in

  (* Generate deployment logic based on deployment order *)
  let deployment_code = Buffer.create 1024 in
  List.iter (fun { edam_name; params } ->
    (* Resolve parameters for deployment, including dependencies *)
    let resolved_params = List.map (fun dep_name ->
      if Hashtbl.mem deployed_instances dep_name then
        Printf.sprintf "%s.address" (find_with_debug deployed_instances dep_name)
      else
        Printf.sprintf "accounts[%s]" dep_name
    ) params in
    Buffer.add_string deployment_code (deploy_edam edam_name resolved_params)
  ) deployment_order;

  (* Handle additional operations in the trace *)
  List.iter (fun (contract_name, (_, Operation operation, participants, data_params), _) ->
    if operation = "start" then (
      (* Resolve all parameters for deployment *)
      let params = resolve_params data_params participants deployed_instances in
      Buffer.add_string deployment_code
        (Printf.sprintf "    const instance_%s = await %s.new(%s);\n" contract_name contract_name params);
      Hashtbl.add deployed_instances contract_name (Printf.sprintf "instance_%s" contract_name)
    )
    else (
      (* Handle other operations *)
      let instance_name = find_with_debug deployed_instances contract_name in
      let params = resolve_params data_params participants deployed_instances in
      Buffer.add_string deployment_code
        (Printf.sprintf "    await %s.%s(%s, { from: accounts[0] });\n" instance_name operation params)
    )
  ) trace;

  Buffer.contents deployment_code


(*generate_hardhat_tests*)  
let generate_hardhat_tests 
(multi_cfg: multi_config) 
traces 
(server_configs: server_config_type) =
  let test_code = Buffer.create 1024 in
  let contracts = Hashtbl.create 10 in

  let get_participants_mapping trace =
    let participants_set = Hashtbl.create 10 in
    let participants_order = ref [] in
  
    (* Collect all participants while skipping EDAM names *)
    List.iter (fun (_, (caller, _,participants, _), _, _, _, _, _) ->
      (* Check if the caller is not a EDAM name and add to the set and order *)
      let caller_id = match caller with PID c -> c  in
      if not (Hashtbl.mem multi_cfg.edam_map caller_id) && not (Hashtbl.mem participants_set caller) then (
        Hashtbl.add participants_set caller ();
        participants_order := !participants_order @ [caller];
      );
  
      (* Iterate over participants and skip EDAM names *)
      List.iter (fun participant ->
        let participant_id = match participant with PID c -> c in
        if not (Hashtbl.mem multi_cfg.edam_map participant_id) && not (Hashtbl.mem participants_set participant) then (
          Hashtbl.add participants_set participant ();
          participants_order := !participants_order @ [participant];
        )
      ) participants
    ) trace;
  
    (* Return participants with their respective indices *)
    List.mapi (fun idx participant ->
      (participant, Printf.sprintf "participant_%s" (match participant with PID id -> id), idx)
    ) !participants_order
  in

  (* Helper to generate parameters including participants and contract addresses *)
  let generate_params data_params participants deployed_addresses dependency_params =
    let dependency_str = String.concat ", " dependency_params in
    let participants_str = String.concat ", " (List.map (
      function (participant) ->
      match participant with
      | PID id -> if not (Hashtbl.mem multi_cfg.edam_map id) then Printf.sprintf "participant_%s" id
        else id
    ) participants) in
    let params_str = get_params_str data_params deployed_addresses in
    String.concat ", " (List.filter ((<>) "") [participants_str; params_str; dependency_str])
  in

  let add_test_of_pi edam instance_name pi iota ptps_list = 
    if server_configs.add_pi_to_test then (
      Buffer.add_string test_code (Printf.sprintf "    // Pi Test \n");
      generate_pi_tests test_code pi iota edam.roles_list ptps_list instance_name ; 
    );
  in
  let add_test_of_state edam to_state instance_name = 
    if server_configs.add_test_of_state then (
      (* Sort states and determine the index of the to_state *)
      let sorted_states = sort_states edam.states in
      let to_state_index = get_state_index to_state sorted_states in
      Buffer.add_string test_code (Printf.sprintf "");
      (* Check the final state (to_state) 
      Buffer.add_string test_code (Printf.sprintf "    // Verify to state:\n");
      Buffer.add_string test_code (Printf.sprintf "    expect(await %s._state()).to.equal(%d);\n" instance_name to_state_index);
      *)
    );
  in
  let add_test_of_variables edam instance_name sigma =
    if edam.variables_list <> [] && server_configs.add_test_of_variables then (
      (* Check the state variables in sigma 
      Buffer.add_string test_code "    // Verify state variables after successful operation:\n";*)
      List.iter (fun (Var v) ->
        match sigma (Var v) with
        | BoolVal b -> 
            Buffer.add_string test_code (Printf.sprintf "    expect(await %s.%s()).to.equal(%b);\n" instance_name v b)
        | IntVal i -> 
            Buffer.add_string test_code (Printf.sprintf "    expect(await %s.%s()).to.equal(%d);\n" instance_name v i)
        | StrVal s -> 
            let regex = Str.regexp_string "Contract" in
            if try Str.search_forward regex s 0 >= 0 with Not_found -> false then 
              let new_s = Str.global_replace regex "" s in
              Buffer.add_string test_code (Printf.sprintf "")
            else 
              Buffer.add_string test_code (Printf.sprintf "    expect(await %s.%s()).to.equal(\"%s\");\n" instance_name v s)
        | _ -> 
            Buffer.add_string test_code (Printf.sprintf "")
      ) edam.variables_list;
      Buffer.add_string test_code (Printf.sprintf "\n");
    )  
  in         

  (* Collect unique contract names globally *)
  List.iter (fun trace ->
    List.iter (fun (contract_name, (caller, Operation operation, _, _), _, _, _, _, _) ->
      if (operation = "start") && not (Hashtbl.mem contracts contract_name) then
        Hashtbl.add contracts contract_name contract_name
    ) trace
  ) traces;
  
  (* Helper to deploy contracts in the correct order *)
  let deploy_in_order deployment_order trace deployed_addresses =
    List.iter (fun deployment_info ->
      let contract_name = deployment_info.edam_name in
      let dependency_params = List.map (fun dep -> Printf.sprintf "instance_%s.target" dep) deployment_info.params in

      (* Filter relevant deployment steps for this trace *)
      List.iter (fun (trace_contract, (caller, Operation operation, participants, data_params), should_succeed, reason, sigma, to_state, transition) ->
        if trace_contract = contract_name && (operation = "start") then (
          (* Generate parameters with dependency info *)
          (*print_endline ("Deploying contract " ^ contract_name ^ " with operation " ^ operation ^ " and transition length ");
          *)
          let edam = find_with_debug multi_cfg.edam_map contract_name in
          let participants_mapping =  get_participants_mapping trace in
          let caller_var = List.assoc caller (List.map (fun (p, v, _) -> (p, v)) participants_mapping) in
          let params = generate_params data_params participants deployed_addresses dependency_params in
          Buffer.add_string test_code (Printf.sprintf "    const contract_factory_%s = await ethers.getContractFactory(\"%s\", %s);\n" contract_name contract_name caller_var);
          Buffer.add_string test_code (Printf.sprintf "    const instance_%s = await contract_factory_%s.deploy(%s);\n" contract_name contract_name params);
          
          Buffer.add_string test_code (Printf.sprintf "    const %s = instance_%s.target;\n" contract_name contract_name);

          let instance_name = (Printf.sprintf "instance_%s" contract_name) in
          Hashtbl.add deployed_addresses contract_name instance_name;

          add_test_of_variables edam instance_name sigma;

          let (_,(_,rho, ptp,_,ptp_list,_,_,rho_prime,_),_) = (match transition with Some t -> t | _ -> failwith "No transition found1") in 
          let iota = generate_iota ((Ptp contract_name) :: (ptp :: ptp_list)) ((PID contract_name):: ([caller] @ participants)) in 
          add_test_of_pi edam instance_name rho_prime iota (ptp :: ptp_list);

          add_test_of_state edam to_state instance_name;
        )
      ) trace
    ) deployment_order
  in

  (* Generate test script *)
  Buffer.add_string test_code "const { expect } = require(\"chai\");\n";
  Buffer.add_string test_code "const { ethers } = require(\"hardhat\");\n\n";
  
  
  Buffer.add_string test_code "describe(\"EDAMs Tests\", function () {\n\n";

  Buffer.add_string test_code "
    let accounts;
  
    before(async function () {
      // Fetch the accounts
      accounts = await ethers.getSigners();
    }) \n\n";
  
  let num_passed_tests = ref 0 in
  let num_failed_tests = ref 0 in
  let num_success_tests = ref 0 in
  let num_failure_tests = ref 0 in

  (* Generate individual test cases for each trace *)
  List.iteri (fun trace_idx trace ->
    Buffer.add_string test_code (Printf.sprintf "\n  it(\"Trace #%d\", async function () {\n" (trace_idx + 1));
    let num_failed_tests_in_trace = ref 0 in
    (* Dynamic participants mapping for this trace *)
    let participants_mapping = get_participants_mapping trace in
    
    List.iter (fun (_, participant_var, idx) ->
      Buffer.add_string test_code (Printf.sprintf "    const %s = accounts[%d];\n" participant_var idx)
    ) participants_mapping;

    (* Get deployment order from compute_edam_deployment_order *)
    let deployment_order = compute_edam_deployment_order multi_cfg.edam_map in
  
    (* Deploy contracts in the correct order *)
    let deployed_addresses = Hashtbl.create 10 in
    deploy_in_order deployment_order trace deployed_addresses;
  
    (* Generate test calls for each operation *)
    List.iteri (fun idx (contract_name, (caller, Operation operation, participants, data_params), should_succeed, reason, sigma, to_state, transition) ->
      if operation <> "start" then (
        let instance_name = find_with_debug deployed_addresses contract_name in
        let edam = find_with_debug multi_cfg.edam_map contract_name in
        
        let caller_var = List.assoc caller (List.map (fun (p, v, _) -> (p, v)) participants_mapping) in
        (* Buffer.add_string test_code (Printf.sprintf "\n    // Test Call #%d: %s\n" (idx + 1) operation); *)
        let params = generate_params data_params participants deployed_addresses [] in
        if not should_succeed then (
          num_failed_tests_in_trace := !num_failed_tests_in_trace + 1;
          num_failed_tests := !num_failed_tests + 1;
          Buffer.add_string test_code "";
          Buffer.add_string test_code (Printf.sprintf "    // %s \n    await expect(%s.connect(%s).%s(%s)).to.be.reverted;\n" reason instance_name caller_var operation params);
        ) else (
          num_passed_tests := !num_passed_tests + 1;
          
          let (_,(_,rho, ptp,_,ptp_list,_,_,rho_prime,_),_) = (match transition with Some t -> t | _ -> failwith "No transition found2") in 
          let iota = generate_iota ((Ptp contract_name) :: (ptp :: ptp_list)) ((PID contract_name):: ([caller] @ participants)) in 
          
          add_test_of_pi edam instance_name rho iota (ptp :: ptp_list);
 
          Buffer.add_string test_code (Printf.sprintf "    // %s \n    await expect(%s.connect(%s).%s(%s)).to.not.be.reverted;\n" reason instance_name caller_var operation params);
          
          add_test_of_variables edam instance_name sigma;
          
          add_test_of_pi edam instance_name rho_prime iota (ptp :: ptp_list);

          add_test_of_state edam to_state instance_name;
        );
      )
    ) trace;
    if !num_failed_tests_in_trace = 0 then
      num_success_tests := !num_success_tests + 1
    else
      num_failure_tests := !num_failure_tests + 1;
    Buffer.add_string test_code "  });\n";
  ) traces;
  
  Buffer.add_string test_code "});\n";
  
  Buffer.add_string test_code (Printf.sprintf 
    "// Passed Calls: %d, Failed Calls: %d, Percentage: %.2f%%\n" 
    !num_passed_tests 
    !num_failed_tests 
    (float_of_int !num_passed_tests /. float_of_int (!num_passed_tests + !num_failed_tests) *. 100.0) 
  );
  
  ("", Buffer.contents test_code)