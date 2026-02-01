#!/bin/bash
set -e  # Exit on error

cd .

rm -f generate_test_trace_text_run # Remove the executable if it exists
eval $(opam env)  # Load OPAM environment

# Compile the source files with ocamlfind and ocamlopt
ocamlfind ocamlopt -thread -package z3 -package str -c types.ml \
  && ocamlfind ocamlopt -thread -package z3 -package str -c printer.ml \
  && ocamlfind ocamlopt -thread -package z3 -package str -c helper.ml \
  && ocamlfind ocamlopt -thread -package z3 -package str -c core_functions.ml \
  && ocamlfind ocamlopt -thread -package z3 -package str -c z3_module.ml \
  && ocamlfind ocamlopt -thread -package z3 -package str -c test_generation.ml \
  && ocamlfind ocamlopt -thread -package z3 -package str -c trace_text_run.ml

# Link the object files to create the executable
ocamlfind ocamlopt -thread -package z3 -package str -linkpkg \
  types.cmx  printer.cmx  helper.cmx  core_functions.cmx z3_module.cmx test_generation.cmx trace_text_run.cmx \
  -o generate_test_trace_text_run

# Clean up intermediate compilation files
rm -f *.cm* *.o

# Execute the generated server executable
./generate_test_trace_text_run

rm -f *.cm* *.o ./generate_test_trace_text_run