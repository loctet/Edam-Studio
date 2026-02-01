open Types
open Printf
open Random
open Str
open Helper
open Printer
open Core_functions
open Test_generation

(*******)

(*Code of  the model here*)
  
{edams_code_here}

(*End Code of  the model here*)

let () = 
  Random.self_init ();

  (* Define the EDAM (including name and roles list) *)
  let server_configs: server_config_type = {
    probability_new_participant = {probability_new_participant};
    probability_right_participant = {probability_right_participant};
    probability_true_for_bool = {probability_true_for_bool};
    min_int_value = {min_int_value};
    max_int_value = {max_int_value};
    max_gen_array_size = {max_gen_array_size};
    min_gen_string_length = {min_gen_string_length};
    max_gen_string_length = {max_gen_string_length};
    z3_check_enabled = {z3_check_enabled};
    latest_transitions = Hashtbl.create 10;
    executed_operations_log = Hashtbl.create 0;
    max_fail_try = {max_fail_try};
    add_pi_to_test = {add_pi_to_test};
    add_test_of_state = {add_test_of_state};
    add_test_of_variables = {add_test_of_variables};
  } in 
  print_endline "++++++++++++++++++++++++";
  (* Generate traces *)
  let traces = 
    List.init {number_symbolic_traces} (fun trace_idx ->
      let multi_cfg_copy = copy_multi_config configurations in
      let new_server_configs = {server_configs with latest_transitions = Hashtbl.create 10; executed_operations_log = Hashtbl.create 0} in
      let (symbolic_trace, generated_trace) = 
        generate_random_trace multi_cfg_copy dependencies_map new_server_configs 
          {number_transition_per_trace} {number_real_traces} (trace_idx + 1) 
      in
      let evaluated_traces = 
        List.map (fun trace -> 
          let evaluated_trace, _ = evaluate_trace (List.rev trace) (copy_multi_config configurations) in
          evaluated_trace
        ) generated_trace 
      in 
      print_symbolic_trace symbolic_trace (trace_idx + 1);
      print_endline "++++++++++++++++++++++++";
      evaluated_traces
    ) 
    |> List.concat 
  in

  print_endline "________";

  (* Generate and print migration and test scripts for all traces *)
  let migration_code, test_code = generate_hardhat_tests configurations traces server_configs in
  print_endline test_code;
  print_endline "________";
  print_endline migration_code;
