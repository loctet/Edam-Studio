"""Templates for test code generation."""

EDAM_TEMPLATE = """
(* Define the EDAM (including name and roles list) *)
let {edam_name}_instance = {edam_code}

let pi_{edam_name} = fun _ -> []
(* Define the initial EDAM configuration *)
let initial_config_{edam_name} = {{
  state = State "_";
  pi = pi_{edam_name};
  sigma = initialize_sigma list_of_vars;
}}

(* Add to the multi_config *)
let () =
  Hashtbl.add configurations.edam_map {edam_name}_instance.name {edam_name}_instance;
  Hashtbl.add configurations.config_map {edam_name}_instance.name initial_config_{edam_name}
"""

CONFIGURATIONS_TEMPLATE = """
(* Define the multi_config structure *)
let configurations : multi_config = {{
  edam_map = Hashtbl.create {size};
  config_map = Hashtbl.create {size};
}}
"""

DEPENDENCIES_MAP_TEMPLATE = """
(* Define the dependencies map for all EDAMs *)
let dependencies_map : dependencies_map = 
  let tbl = Hashtbl.create {size} in
{dependency_entries}
  tbl
"""

DEPENDENCY_ENTRY_TEMPLATE = """
  (* Define the dependency for {edam_name} *)
  let dependency_{edam_name} = {{
    required_calls = [];
    participant_roles = [];
    can_generate_participants = [];
    can_generate_participants_vars = [];
    transition_probabilities = Hashtbl.create 10;
  }} in
  Hashtbl.add tbl {edam_name}_instance.name dependency_{edam_name};
""" 