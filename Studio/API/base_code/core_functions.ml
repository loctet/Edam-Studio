open Types
open Helper
open Printer


(* Define rho: Mapping from roles to role attributes *)
let topEverywhere : role_mode_type = fun _ -> Top

(* Function to update the pi function based on the given iota, pi mappings, and a list of roles *)
let update_pi (pi : pi_type) (iota : iota_type) (rho : role_a_type) (party_list: ptp_var list) (roles: role_type list) : pi_type =
  fun alpha ->
    let original_roles = pi alpha in
    let ptp_vars = List.filter (fun ptp -> iota ptp = alpha) party_list in
    (* First phase: collect all roles that should be added (Top) *)
    let roles_to_add = ref [] in
    List.iter (fun ptp_var ->
      List.iter (fun role ->
        match rho ptp_var role with 
        | Top -> if not (List.mem role !roles_to_add) && not (List.mem role original_roles) 
                 then roles_to_add := !roles_to_add @ [role]
        | _ -> ()
      ) roles
    ) ptp_vars;
    (* Second phase: collect all roles that should be removed (Bottom) *)
    let roles_to_remove = ref [] in
    List.iter (fun ptp_var ->
      List.iter (fun role ->
        match rho ptp_var role with 
        | Bottom -> if not (List.mem role !roles_to_remove) 
                    then roles_to_remove := !roles_to_remove @ [role]
        | _ -> ()
      ) roles
    ) ptp_vars;
    (* Apply changes: first add all Top roles, then remove all Bottom roles *)
    let updated_roles = original_roles @ !roles_to_add in
    List.filter (fun r -> not (List.mem r !roles_to_remove)) updated_roles

(* Main function to check the compatibility of role modes for all participants *)
let rec bowtie (iota : iota_type) (rho: role_a_type) (party_list: ptp_var list) (role_list: role_type list) =
  let rec check_rest_participants partyP identity = function
    | [] -> true
    | partyP' :: rest' ->
      let identity' = iota partyP' in
      if identity = identity' then
        check_role_modes_for_pair (rho partyP) (rho partyP') role_list && check_rest_participants partyP identity rest'
      else
        check_rest_participants partyP identity rest'
  in
  match party_list with
  | [] -> true
  | partyP :: rest ->
    let identity = iota partyP in
    check_rest_participants partyP identity rest && bowtie iota rho rest role_list


  
(* Check if pi models iota and rho *)
let role_satisf (pi: pi_type) (iota: iota_type) (rho: role_a_type) (participant_vars: ptp_var list) (roles: role_type list) : bool =
  (* Get unique participant IDs *)
  let unique_participants = 
    remove_duplicates (List.map iota participant_vars)
  in
  (* For each unique participant ID, check the conditions *)
  List.for_all (fun participant ->
    let participant_roles = pi participant in
    (* Get all party variables that map to this participant ID *)
    let party_vars_for_participant = List.filter (fun partyP -> iota partyP = participant) participant_vars in
    (* Collect all roles marked as Top (hasrole) across all party variables for this participant *)
    let hasrole_roles = ref [] in
    List.iter (fun partyP ->
      List.iter (fun roleR ->
        if rho partyP roleR = Top && not (List.mem roleR !hasrole_roles) then
          hasrole_roles := !hasrole_roles @ [roleR]
      ) roles
    ) party_vars_for_participant;
    (* Collect all roles marked as Bottom (notrole) across all party variables for this participant *)
    let notrole_roles = ref [] in
    List.iter (fun partyP ->
      List.iter (fun roleR ->
        if rho partyP roleR = Bottom && not (List.mem roleR !notrole_roles) then
          notrole_roles := !notrole_roles @ [roleR]
      ) roles
    ) party_vars_for_participant;
    (* Check: participant_roles ∩ notrole_roles = ∅ *)
    let intersection_empty = List.for_all (fun roleR -> not (List.mem roleR participant_roles)) !notrole_roles in
    (* Check: hasrole_roles ⊆ participant_roles *)
    let subset_condition = List.for_all (fun roleR -> List.mem roleR participant_roles) !hasrole_roles in
    intersection_empty && subset_condition
  ) unique_participants

(* Update iota mapping *)
let update_iota (iota: iota_type) (ys: ptp_var list) (betas: participant list) : iota_type =
  let updates = List.combine ys betas in
  fun partyP ->
    try
      List.assoc partyP updates
    with Not_found ->
      iota partyP

(* Validate edams *)
let validate_edams (multi_config : multi_config) : (string * bool) list =
  let check_edam_validity edam =
    let start_transitions = List.filter (fun (from_state, (_, _, _, op, _, _, _, _, _), to_state) -> 
      op = Operation "start") edam.transitions in
    let other_transitions = List.filter (fun (from_state, (_, _, _, op, _, _, _, _, _), to_state) -> 
      op <> Operation "start") edam.transitions in
    
    match start_transitions with
    | [(State "_", (_, _, _, _, _, _, _, _, _), State target)] when target <> "_" ->
      (* There is exactly one valid "start" transition *)
      let valid_other_transitions = List.for_all (fun (State from, _, State to_) -> from <> "_" && to_ <> "_") other_transitions in
      valid_other_transitions
    | _ -> false (* No valid start transition or multiple "start" transitions *)
  in
  Hashtbl.fold (fun edam_name edam acc -> (edam_name, check_edam_validity edam) :: acc) multi_config.edam_map []
      


(* Check if a given transition satisfies the premises and return the new configuration *)
let check_transition 
  (edam_name: string)
  (config: configuration) 
  (transition: transition_type) 
  (label_conf: label_conf) 
  (iota: iota_type) 
  (roles: role_type list) 
  (ptpV_list: ptp_var list) 
  (multi_cfg: multi_config) 
  (called_contracts: string list)
: (configuration option * string option * multi_config) =
  let { state = q; pi = current_pi; sigma = current_sigma } = config in
  let (participant, operation, participants, values) = label_conf in
  let (q_from, ((guard,list_of_calls), rho, ptp, op, ptp_list, dvar_list_with_type, assign_list, rho', _), q_to) = transition in
  let dvar_list = List.map snd dvar_list_with_type in

  if q <> q_from then
    (None, Some "Current state does not match the transition's source state.", multi_cfg)
  else if op <> operation then
    (None, Some "Operation does not match the transition's expected operation.", multi_cfg)
  else
    let iota_updated = iota in
    let sub_map = List.combine dvar_list values in
    let new_sigma = substitute_values current_sigma sub_map in
    let (guard_val, multi_cfg') =  
        try 
          eval new_sigma iota_updated guard multi_cfg called_contracts
        with _ -> (BoolVal false, multi_cfg) 
    in
    if match guard_val with BoolVal true -> true | _ -> false then
      let (list_of_calls_val, multi_cfg1) =  
          try 
            eval_func_write_list edam_name list_of_calls new_sigma iota_updated  multi_cfg' called_contracts
          with _ -> (false, multi_cfg') 
      in
      if list_of_calls_val then
        if List.for_all2 (fun y beta -> iota_updated y = beta) ptp_list participants then
          let alpha = iota_updated ptp in
          if alpha = participant then
            let ptp_list_updated = remove_duplicates (ptp :: (ptp_list @ ptpV_list)) in
            let pi_models = role_satisf current_pi iota_updated rho ptp_list_updated roles in
            let new_pi = update_pi current_pi iota_updated rho' ptp_list_updated roles in
            let pi_models_prime = role_satisf new_pi iota_updated rho' ptp_list_updated roles in
            (* let bowtie_check = bowtie iota_updated rho ptp_list (current_pi alpha) in *)
            if pi_models then 
              if pi_models_prime then
                let result =
                  try 
                    Some (
                      List.fold_left (
                        fun s (d, e) -> update s d (fst (eval new_sigma iota_updated e multi_cfg1 called_contracts))
                        ) new_sigma assign_list
                    )
                  with _ -> None 
                in
              
                match result with
                | None -> (None, Some "Failed to evaluate sigma during transition.", multi_cfg)
                | Some final_sigma -> 
                    let new_config = { state = q_to; pi = new_pi; sigma = final_sigma } in
                    (* let () = print_transition_details transition iota final_sigma " ✅" in
                      let () = print_participants_and_roles new_config iota ptp_list_updated in *)
                    (Some new_config, None, multi_cfg1)
              else
                (None, Some "Role entail pi_models_prime failed.", multi_cfg)            
            else 
              (None, Some "role_satisf validation failed.", multi_cfg)
          else
            (None, Some "Caller does not match the expected participant.", multi_cfg)
        else
          (None, Some "Participants in label configuration do not match transition requirements.", multi_cfg)
      else(
        (* print_endline "List of calls condition failed."; *)
        (None, Some "List of calls condition failed.", multi_cfg))
    else(
      (* print_endline "Guard condition failed."; *)
      (None, Some "Guard condition failed.", multi_cfg))

(* Perform a transition if it is valid, returning the new configuration and updated edam *)
let perform_transition_impl 
  (origin_edam_name: string)
  (config: configuration) 
  (label_conf: label_conf) 
  (edam: edam_type) 
  (iota: iota_type) 
  (original_multi_cfg: multi_config) 
  (called_contracts: string list)  
: (configuration option * edam_type option * multi_config option * transition_type option * string option) option =
  let (_, op1, _, _) = label_conf in 
  (* Printf.printf "List of called contracts: edam %s op %s : reentrancy: %b\n" edam.name (string_of_op op1) (List.mem edam.name called_contracts);
  Printer.print_list called_contracts; *)
  (* print_endline ("edam.name: " ^ origin_edam_name); *)
  if List.mem edam.name called_contracts then
    failwith "Reentrancy detected in FuncCallEdamWrite";
  let called_contracts_updated = called_contracts @ [edam.name] in

  let { state = current_state; pi = current_pi; sigma = current_sigma } = config in
  let potential_transitions = List.filter (fun (q, label, q') ->
    let (_, _, _, op, _, _, _, _, _) = label in
    q = current_state && op = (let (_, op, _, _) = label_conf in op)
  ) edam.transitions in

  (* Preserve original multi_cfg to revert if all transitions fail *)
  let multi_cfg  = copy_multi_config original_multi_cfg in

  (* Helper to find a valid transition or aggregate failure reasons *)
  let rec find_valid_transition 
      (multi_cfg: multi_config) 
      (failure_reasons: string list) 
      (remaining_transitions: transition_type list) 
    : (configuration option * edam_type option * multi_config option * transition_type option * string option) option =
    match remaining_transitions with
    | [] -> 
        (* All transitions failed, return the original multi_cfg and aggregated reasons *)
        Some (None, None, Some original_multi_cfg, None, Some (String.concat "; " failure_reasons))
    | transition :: rest ->
      let (result_config, failure_reason, updated_multi_cfg) =
        check_transition origin_edam_name config transition label_conf iota edam.roles_list edam.ptp_var_list multi_cfg called_contracts_updated
      in
      match result_config with
      | Some new_config ->
        let (from_state, (_, _, ptp, op, ptp_list, _, _, _, _), to_state) = transition in
        let updated_ptp_var_list = remove_duplicates (ptp :: (ptp_list @ edam.ptp_var_list)) in
        let updated_edam = { edam with ptp_var_list = updated_ptp_var_list } in
        Hashtbl.replace updated_multi_cfg.config_map edam.name new_config;
        Hashtbl.replace updated_multi_cfg.edam_map edam.name updated_edam;
        (* Printf.printf "\n ✅ In process Operation %s\n" (string_of_op op); 
        print_all_sigmas updated_multi_cfg;*)
        Some (Some new_config, Some updated_edam, Some updated_multi_cfg, Some transition, Some (String.concat " -> " [ (match from_state with | State s -> s); (match to_state with | State s -> s) ]))
      | None ->
        let updated_reasons = match failure_reason with
          | Some reason -> failure_reasons @ [reason]
          | None -> failure_reasons
        in
        find_valid_transition updated_multi_cfg updated_reasons rest
  in

  (* Handle the case where no potential transitions exist *)
  if potential_transitions = [] then
    let reason = Printf.sprintf "No potential_transitions in current_state = %s" (match current_state with | State s -> s) in
    Some (None, None, Some original_multi_cfg, None, Some reason)
  else
    match find_valid_transition multi_cfg [] potential_transitions with
    | Some (None, None, Some reverted_multi_cfg, None, Some failure_reasons) ->
      (* All transitions failed, reverting multi_cfg to original state *)
      Some (None, None, Some reverted_multi_cfg, None, Some failure_reasons)
    | Some (new_config, updated_edam, Some updated_multi_cfg, transition, reason) ->
      (* A valid transition was found *)
      Some (new_config, updated_edam, Some updated_multi_cfg, transition, reason)
    | _ ->
      (* This should not happen, but handle unexpected cases *)
      Some (None, None, Some original_multi_cfg, None, Some "Unexpected error in transition processing.")


    
let () = perform_transition := perform_transition_impl



(* Function to evaluate a trace and return a new trace with success/failure status *)
let evaluate_trace (trace: (string * label_conf) list) configurations : 
  ((string * label_conf * bool * string * sigma_type * state_type * transition_type option) list) * multi_config =
  
  (* Helper function to perform a transition and determine success/failure *)
  let perform_trace_transition (edam_name: string) (label_conf: label_conf) iota (multi_cfg: multi_config) =
    let _, op, _, _ = label_conf in
    (* Printf.printf "\n ❌  ❌  ❌  ❌  ❌ %s \n" (string_of_op op);
    print_all_sigmas multi_cfg; *)
    let config = find_with_debug multi_cfg.config_map edam_name in
    let edam = find_with_debug multi_cfg.edam_map edam_name in
    
    match !perform_transition edam_name config label_conf edam iota multi_cfg [] with
    | Some (Some(new_config), Some(new_edam), Some(updated_multi_cfg), transition, reason) ->
        (* Printf.printf "\n ✅ Operation %s\n" (string_of_op op);
        print_all_sigmas updated_multi_cfg; *)
        (true, reason, new_config.sigma, new_config.state, transition, Some updated_multi_cfg)

    | Some (None, _, _, transition, reason) -> 
       (*  Printf.printf "\n ❌ Operation %s %s \n" (string_of_op op) (match reason with Some r -> r);
        print_all_sigmas multi_cfg; *)
        (false, reason, config.sigma, config.state, transition, Some multi_cfg)

    | _ -> 
        Printf.printf "Error in perform_trace_transition\n"; 
        (false, Some("Error"), config.sigma, config.state, None, Some multi_cfg)
  in

  (* Evaluate each transition in the trace and accumulate the updated multi_cfg *)
  let result_trace, updated_multi_cfg = 
    List.fold_left (fun (acc, current_multi_cfg) (edam_name, label_conf) ->
      let iota = generate_iota_from_label edam_name label_conf configurations in
      let success, reason, sigma, state, transition, updated_multi_cfg = 
        perform_trace_transition edam_name label_conf iota current_multi_cfg 
      in
      ((edam_name, label_conf, success, (match reason with | Some s -> s | None -> ""), sigma, state, transition) :: acc, 
       match updated_multi_cfg with Some cfg -> cfg | None -> current_multi_cfg)
    ) ([], configurations) trace
  in
  (* print_all_sigmas updated_multi_cfg;  *)
  (List.rev result_trace, updated_multi_cfg)  (* Reverse the list to maintain original order *)




(* Function to evaluate a trace and return a new trace with success/failure status *)
let evaluate_trace_last (last_trace: (string * label_conf) list) previous_trace configurations : 
  (string * label_conf * bool * string * sigma_type * state_type * transition_type option) list =
  
  let (result, _) = evaluate_trace last_trace configurations in
  previous_trace @ result 

