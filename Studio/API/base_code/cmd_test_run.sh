#!/bin/bash
set -e  # Exit on error

cd /temp

rm -f generate_test_{file_name} # Remove the executable if it exists
eval $(opam env)  # Load OPAM environment

# Compile the source files with ocamlfind and ocamlopt
ocamlfind ocamlopt -thread -package z3 -package str -c types.ml \
  && ocamlfind ocamlopt -thread -package z3 -package str -c printer.ml \
  && ocamlfind ocamlopt -thread -package z3 -package str -c helper.ml \
  && ocamlfind ocamlopt -thread -package z3 -package str -c core_functions.ml \
  && ocamlfind ocamlopt -thread -package z3 -package str -c {file_name}.ml

# Link the object files to create the executable
ocamlfind ocamlopt -thread -package z3 -package str -linkpkg \
  types.cmx  printer.cmx  helper.cmx  core_functions.cmx  {file_name}.cmx \
  -o generate_test_{file_name}

# Clean up intermediate compilation files
rm -f *.cm* *.o

# Execute the generated server executable
./generate_test_{file_name}