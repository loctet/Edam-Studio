const fs = require("fs");

const initialConfig = {
    probability_new_participant: 0.01,
    probability_right_participant: 0.7,
    probability_true_for_bool: 0.5,
    min_int_value: 0,
    max_int_value: 100,
    max_gen_array_size: 10,
    min_gen_string_length: 5,
    max_gen_string_length: 10,
    z3_check_enabled: true,
    number_symbolic_traces: 200,
    number_transition_per_trace: 10,
    number_real_traces: 5,
    max_fail_try: 2,
    add_pi_to_test: false,
    add_test_of_state: true,
    add_test_of_variables: true
};

// Function to get configuration settings
function getConfigSettings() {
    return initialConfig;
}

module.exports = { getConfigSettings };
