#!/bin/bash
set -e  # Exit on error
rm -f generate_test # Remove the executable if it exists
eval $(opam env)  # Load OPAM environment

# Compile the source files with ocamlfind and ocamlopt
ocamlfind ocamlopt -thread -package z3 -package str -c types.ml \
  && ocamlfind ocamlopt -thread -package z3 -package str -c printer.ml \
  && ocamlfind ocamlopt -thread -package z3 -package str -c helper.ml \
  && ocamlfind ocamlopt -thread -package z3 -package str -c z3_module.ml \
  && ocamlfind ocamlopt -thread -package z3 -package str -c test_z3.ml \
  && ocamlfind ocamlopt -thread -package z3 -package str -linkpkg z3_module.cmx -c test_z3.ml 

# Link the object files to create the executable
ocamlfind ocamlopt -thread -package z3 -package str -linkpkg \
  types.cmx printer.cmx helper.cmx z3_module.cmx test_z3.cmx \
  -o generate_test

# Clean up intermediate compilation files
rm -f *.cm* *.o

# Execute the generated server executable
./generate_test