open Str
open Types
open Helper


{edams_code_here}

{call_list_here}

let () = 
  print_endline "________";
  let evaluated_trace = Core_functions.evaluate_trace calls_list configurations in
  Printer.print_trace evaluated_trace;