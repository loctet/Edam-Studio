open Types
open Z3

(* Function to convert a guard_type into a z3_exp *)
let guard_to_z3_exp (guard: guard_type) : z3_exp =
    let (main_exp, calls) = guard in
    
    (* Convert each (FuncCallEdamWrite, bool) pair into an equality expression *)
    let call_expressions = List.map (fun (call, expected_bool) -> Z_Eq (call, expected_bool)) calls in
  
    (* Fold the list into a conjunction of all expressions *)
    let combined_calls = 
      match call_expressions with
      | [] -> Z_Exp main_exp  (* If no function calls, return only the main expression *)
      | _ -> List.fold_left (fun acc expr -> Z_And (acc, expr)) (Z_Exp main_exp) call_expressions
    in
    combined_calls
  
    
(* Helper function to build a dvar mapping with unique substitutions *)
let build_dvar_map (dvar_bindings: (dvar_type * dvar) list) (values: z3_exp list) : (dvar, exp) Hashtbl.t =
  let dvar_map = Hashtbl.create (List.length dvar_bindings) in
  List.iter2 (fun (_, dvar) value -> Hashtbl.replace dvar_map dvar (match value with Z_Exp e -> e)) dvar_bindings values;
  dvar_map

(* Updated substitution function for z3_exp *)
let rec substitute_params 
    (exp : z3_exp) 
    (dvar_map : (dvar, exp) Hashtbl.t) 
    (ptp_map : (ptp_var * exp) list) 
  : z3_exp =
  match exp with
  | Z_Exp e -> Z_Exp (substitute_exp e dvar_map ptp_map)  (* Delegate to exp substitution *)
  | Z_Call (FuncCallEdamWrite (edam_name, op, vals, parts)) ->
      let new_vals = List.map (fun v -> substitute_exp v dvar_map ptp_map) vals in
      let new_parts = List.map (fun p -> substitute_exp p dvar_map ptp_map) parts in
      Z_Call (FuncCallEdamWrite (edam_name, op, new_vals, new_parts))
  | Z_And (e1, e2) -> Z_And (substitute_params e1 dvar_map ptp_map, substitute_params e2 dvar_map ptp_map)
  | Z_Eq (call, bool_val) -> Z_Eq (substitute_func_write call dvar_map ptp_map, bool_val)

(* Helper function to substitute inside exp *)
and substitute_exp (e : exp) (dvar_map : (dvar, exp) Hashtbl.t) (ptp_map : (ptp_var * exp) list) : exp =
  match e with
  | Pvar_a p -> (try List.assoc p ptp_map with Not_found -> Pvar_a p)
  | Dvar v -> (try Hashtbl.find dvar_map v with Not_found -> Dvar v)
  | Plus (e1, e2) -> Plus (substitute_exp e1 dvar_map ptp_map, substitute_exp e2 dvar_map ptp_map)
  | Minus (e1, e2) -> Minus (substitute_exp e1 dvar_map ptp_map, substitute_exp e2 dvar_map ptp_map)
  | Times (e1, e2) -> Times (substitute_exp e1 dvar_map ptp_map, substitute_exp e2 dvar_map ptp_map)
  | Divide (e1, e2) -> Divide (substitute_exp e1 dvar_map ptp_map, substitute_exp e2 dvar_map ptp_map)
  | And (e1, e2) -> And (substitute_exp e1 dvar_map ptp_map, substitute_exp e2 dvar_map ptp_map)
  | Or (e1, e2) -> Or (substitute_exp e1 dvar_map ptp_map, substitute_exp e2 dvar_map ptp_map)
  | Not e -> Not (substitute_exp e dvar_map ptp_map)
  | Equal (e1, e2) -> Equal (substitute_exp e1 dvar_map ptp_map, substitute_exp e2 dvar_map ptp_map)
  | NotEqual (e1, e2) -> NotEqual (substitute_exp e1 dvar_map ptp_map, substitute_exp e2 dvar_map ptp_map)
  | GreaterThan (e1, e2) -> GreaterThan (substitute_exp e1 dvar_map ptp_map, substitute_exp e2 dvar_map ptp_map)
  | GreaterThanEqual (e1, e2) -> GreaterThanEqual (substitute_exp e1 dvar_map ptp_map, substitute_exp e2 dvar_map ptp_map)
  | LessThan (e1, e2) -> LessThan (substitute_exp e1 dvar_map ptp_map, substitute_exp e2 dvar_map ptp_map)
  | LessThanEqual (e1, e2) -> LessThanEqual (substitute_exp e1 dvar_map ptp_map, substitute_exp e2 dvar_map ptp_map)
  | FuncCall (name, args) -> FuncCall (name, List.map (fun arg -> substitute_exp arg dvar_map ptp_map) args)
  | Val v -> Val v
  | _ -> e

(* Helper function to substitute inside FuncCallEdamWrite *)
and substitute_func_write (call : funcCallEdamWrite) (dvar_map : (dvar, exp) Hashtbl.t) (ptp_map : (ptp_var * exp) list) : funcCallEdamWrite =
  match call with
  | FuncCallEdamWrite (edam_name, op, vals, parts) ->
      let new_vals = List.map (fun v -> substitute_exp v dvar_map ptp_map) vals in
      let new_parts = List.map (fun p -> substitute_exp p dvar_map ptp_map) parts in
      FuncCallEdamWrite (edam_name, op, new_vals, new_parts)


(* Define a function to replace dvars with their corresponding values in z3_exp *)
let rec replace_dvars (exp : z3_exp) (sigma : sigma_type) : z3_exp =
    match exp with
    | Z_Exp e -> Z_Exp (replace_dvars_in_exp e sigma)  (* Delegate replacement for regular expressions *)
    | Z_Call (FuncCallEdamWrite (name, op, vals, parts)) ->
        Z_Call (
          FuncCallEdamWrite (
            name, 
            op, 
            List.map (fun v -> replace_dvars_in_exp v sigma) vals, 
            List.map (fun p -> replace_dvars_in_exp p sigma) parts
          )
        )
    | Z_And (e1, e2) -> Z_And (replace_dvars e1 sigma, replace_dvars e2 sigma)
    | Z_Eq (call, bool_val) -> Z_Eq (replace_dvars_in_func_call call sigma, bool_val)
  
  (* Helper function to replace dvars inside exp *)
  and replace_dvars_in_exp (e : exp) (sigma : sigma_type) : exp =
    match e with
    | Dvar d when Printer.sigma_contains sigma d -> Val (sigma d)
    | Plus (e1, e2) -> Plus (replace_dvars_in_exp e1 sigma, replace_dvars_in_exp e2 sigma)
    | Minus (e1, e2) -> Minus (replace_dvars_in_exp e1 sigma, replace_dvars_in_exp e2 sigma)
    | Times (e1, e2) -> Times (replace_dvars_in_exp e1 sigma, replace_dvars_in_exp e2 sigma)
    | Divide (e1, e2) -> Divide (replace_dvars_in_exp e1 sigma, replace_dvars_in_exp e2 sigma)
    | And (e1, e2) -> And (replace_dvars_in_exp e1 sigma, replace_dvars_in_exp e2 sigma)
    | Or (e1, e2) -> Or (replace_dvars_in_exp e1 sigma, replace_dvars_in_exp e2 sigma)
    | Not e -> Not (replace_dvars_in_exp e sigma)
    | Equal (e1, e2) -> Equal (replace_dvars_in_exp e1 sigma, replace_dvars_in_exp e2 sigma)
    | NotEqual (e1, e2) -> NotEqual (replace_dvars_in_exp e1 sigma, replace_dvars_in_exp e2 sigma)
    | GreaterThan (e1, e2) -> GreaterThan (replace_dvars_in_exp e1 sigma, replace_dvars_in_exp e2 sigma)
    | GreaterThanEqual (e1, e2) -> GreaterThanEqual (replace_dvars_in_exp e1 sigma, replace_dvars_in_exp e2 sigma)
    | LessThan (e1, e2) -> LessThan (replace_dvars_in_exp e1 sigma, replace_dvars_in_exp e2 sigma)
    | LessThanEqual (e1, e2) -> LessThanEqual (replace_dvars_in_exp e1 sigma, replace_dvars_in_exp e2 sigma)
    | FuncCall (name, args) -> FuncCall (name, List.map (fun arg -> replace_dvars_in_exp arg sigma) args)
    | FuncCallEdamRead (name, arg) -> FuncCallEdamRead (name, replace_dvars_in_exp arg sigma)
    | ListIndex (list_exp, index_exp, default_exp) -> 
        ListIndex (replace_dvars_in_exp list_exp sigma, replace_dvars_in_exp index_exp sigma, replace_dvars_in_exp default_exp sigma)
    | MapIndex (map_exp, key_exp, default_exp) -> 
        MapIndex (replace_dvars_in_exp map_exp sigma, replace_dvars_in_exp key_exp sigma, replace_dvars_in_exp default_exp sigma)
    | _ -> e  (* Return unchanged if it's already a value *)
  
  (* Helper function to replace dvars inside FuncCallEdamWrite *)
  and replace_dvars_in_func_call (call : funcCallEdamWrite) (sigma : sigma_type) : funcCallEdamWrite =
    match call with
    | FuncCallEdamWrite (name, op, vals, parts) ->
        FuncCallEdamWrite (
          name, 
          op, 
          List.map (fun v -> replace_dvars_in_exp v sigma) vals, 
          List.map (fun p -> replace_dvars_in_exp p sigma) parts
        )
  
(* Define a function to convert a guard expression into a Z3 expression *)
(* Convert a z3_exp into a Z3 expression *)
let rec z3_of_z3_exp
    (ctx : Z3.context) 
    (sigma : sigma_type) 
    (iota : iota_type) 
    (multi_cfg : multi_config) 
    (z3_vars : (string, Z3.Expr.expr) Hashtbl.t) 
    (e : z3_exp) 
    (dvar_list: (dvar_type * dvar) list) 
    (called_contracts: string list ref) (* Track contract calls for reentrancy prevention *)
: Z3.Expr.expr = 
  match e with
    | Z_Exp exp -> z3_of_exp ctx sigma iota multi_cfg z3_vars exp dvar_list called_contracts
    | Z_Call call -> z3_of_func_write ctx sigma iota multi_cfg z3_vars call dvar_list called_contracts
    | Z_And (e1, e2) -> 
        Z3.Boolean.mk_and ctx [z3_of_z3_exp ctx sigma iota multi_cfg z3_vars e1 dvar_list called_contracts;
                                z3_of_z3_exp ctx sigma iota multi_cfg z3_vars e2 dvar_list called_contracts]
    | Z_Eq (call, expected_bool) -> 
      let call_expr = z3_of_func_write ctx sigma iota multi_cfg z3_vars call dvar_list called_contracts in
      let bool_expr = Z3.Boolean.mk_val ctx expected_bool in
      Z3.Boolean.mk_eq ctx call_expr bool_expr

   (* Convert an exp into a Z3 expression *)
and z3_of_exp
(ctx : Z3.context) 
(sigma : sigma_type) 
(iota : iota_type) 
(multi_cfg : multi_config) 
(z3_vars : (string, Z3.Expr.expr) Hashtbl.t) 
(e : exp) 
(dvar_list: (dvar_type * dvar) list) 
(called_contracts: string list ref) 
: Z3.Expr.expr =   
    (* Helper function to find a variable's type from dvar_list *)
    let find_dvar_type (v: string) : dvar_type option =
        List.find_opt (fun (_, Var var) -> var = v) dvar_list |> Option.map fst in
    
    match e with
    | Pvar_a (Ptp s) ->
        if not (Hashtbl.mem z3_vars s) then
            let z3_var = Z3.Seq.mk_string ctx s in
            Hashtbl.add z3_vars s z3_var;
            z3_var
        else
            Hashtbl.find z3_vars s
  
    | Dvar (Var v) ->
      (* Printf.printf "Looking for variable %s\n" v; *)
      (* First, check if the variable is already assigned a value in sigma *)
      if Printer.sigma_contains sigma (Var v) then
          (* Retrieve the value from sigma and return the corresponding Z3 expression *)
          let value = sigma (Var v) in
          (* Printf.printf "Found variable %s in sigma\n" v; *)
          (match value with
          | BoolVal b -> Z3.Boolean.mk_val ctx b
          | IntVal i -> Z3.Arithmetic.Integer.mk_numeral_i ctx i
          | StrVal s -> Z3.Seq.mk_string ctx s
          | _ -> failwith "Unsupported value type in sigma")
      else (
          (* If not in sigma, check its type from dvar_list *)
          match find_dvar_type v with
          | Some (VarT "bool") -> 
              (* Create a fresh Z3 boolean variable *)
              if not (Hashtbl.mem z3_vars v) then
                  let z3_var = Z3.Boolean.mk_const_s ctx v in
                  Hashtbl.add z3_vars v z3_var;
                  z3_var
              else Hashtbl.find z3_vars v
  
          | Some (VarT "int") | Some (VarT "uint") -> 
              (* Create a fresh Z3 integer variable *)
              if not (Hashtbl.mem z3_vars v) then
                  let z3_var = Z3.Arithmetic.Integer.mk_const_s ctx v in
                  Hashtbl.add z3_vars v z3_var;
                  z3_var
              else Hashtbl.find z3_vars v
  
          | Some (VarT "string") | Some (VarT "address") ->
              (* Create a fresh Z3 string variable *)
              if not (Hashtbl.mem z3_vars v) then
                  let z3_var = Z3.Seq.mk_string ctx v in
                  Hashtbl.add z3_vars v z3_var;
                  z3_var
              else Hashtbl.find z3_vars v
  
          | Some _ -> 
              Printf.printf "Unsupported variable type in dvar_list: %s\n" v;
              failwith ("Unsupported variable type in dvar_list " ^ v)
  
          | None -> 
              (* If the variable is not in sigma or dvar_list, create a fresh integer variable *)
              if not (Hashtbl.mem z3_vars v) then
                  let z3_var = Z3.Arithmetic.Integer.mk_const_s ctx v in
                  Hashtbl.add z3_vars v z3_var;
                  z3_var
              else 
                Hashtbl.find z3_vars v
      )
    | PtpEqPtp (p1, p2) ->
        let (e1', _) = Helper.eval sigma iota (PtID p1) multi_cfg !called_contracts in
        let (e2', _) = Helper.eval sigma iota (PtID p2) multi_cfg !called_contracts in
        Z3.Boolean.mk_eq ctx (Z3.Seq.mk_string ctx (match e1' with PtpID (PID i1) -> i1))  (Z3.Seq.mk_string ctx (match e2' with PtpID (PID i2) -> i2))
    | Plus (e1, e2) ->
        let e1' = z3_of_exp ctx sigma iota multi_cfg z3_vars e1 dvar_list called_contracts in
        let e2' = z3_of_exp ctx sigma iota multi_cfg z3_vars e2 dvar_list called_contracts in
        Z3.Arithmetic.mk_add ctx [e1'; e2']
  
    | Minus (e1, e2) ->
        let e1' = z3_of_exp ctx sigma iota multi_cfg z3_vars e1 dvar_list called_contracts in
        let e2' = z3_of_exp ctx sigma iota multi_cfg z3_vars e2 dvar_list called_contracts in
        Z3.Arithmetic.mk_sub ctx [e1'; e2']
  
    | Times (e1, e2) ->
        let e1' = z3_of_exp ctx sigma iota multi_cfg z3_vars e1 dvar_list called_contracts in
        let e2' = z3_of_exp ctx sigma iota multi_cfg z3_vars e2 dvar_list called_contracts in
        Z3.Arithmetic.mk_mul ctx [e1'; e2']
  
    | Divide (e1, e2) ->
        let e1' = z3_of_exp ctx sigma iota multi_cfg z3_vars e1 dvar_list called_contracts in
        let e2' = z3_of_exp ctx sigma iota multi_cfg z3_vars e2 dvar_list called_contracts in
        Z3.Arithmetic.mk_div ctx e1' e2'
  
    | And (e1, e2) ->
        let e1' = z3_of_exp ctx sigma iota multi_cfg z3_vars e1 dvar_list called_contracts in
        let e2' = z3_of_exp ctx sigma iota multi_cfg z3_vars e2 dvar_list called_contracts in
        Z3.Boolean.mk_and ctx [e1'; e2']
  
    | Or (e1, e2) ->
        let e1' = z3_of_exp ctx sigma iota multi_cfg z3_vars e1 dvar_list called_contracts in
        let e2' = z3_of_exp ctx sigma iota multi_cfg z3_vars e2 dvar_list called_contracts in
        Z3.Boolean.mk_or ctx [e1'; e2']
  
    | Not e ->
        let e' = z3_of_exp ctx sigma iota multi_cfg z3_vars e dvar_list called_contracts in
        Z3.Boolean.mk_not ctx e'
  
    | Equal (e1, e2) ->
        let e1' = z3_of_exp ctx sigma iota multi_cfg z3_vars e1 dvar_list called_contracts in
        let e2' = z3_of_exp ctx sigma iota multi_cfg z3_vars e2 dvar_list called_contracts in
        Z3.Boolean.mk_eq ctx e1' e2'
  
    | NotEqual (e1, e2) ->
        let e1' = z3_of_exp ctx sigma iota multi_cfg z3_vars e1 dvar_list called_contracts in
        let e2' = z3_of_exp ctx sigma iota multi_cfg z3_vars e2 dvar_list called_contracts in
        Z3.Boolean.mk_not ctx (Z3.Boolean.mk_eq ctx e1' e2')
  
    | GreaterThan (e1, e2) ->
        let e1' = z3_of_exp ctx sigma iota multi_cfg z3_vars e1 dvar_list called_contracts in
        let e2' = z3_of_exp ctx sigma iota multi_cfg z3_vars e2 dvar_list called_contracts in
        Z3.Arithmetic.mk_gt ctx e1' e2'
  
    | GreaterThanEqual (e1, e2) ->
        let e1' = z3_of_exp ctx sigma iota multi_cfg z3_vars e1 dvar_list called_contracts in
        let e2' = z3_of_exp ctx sigma iota multi_cfg z3_vars e2 dvar_list called_contracts in
        Z3.Arithmetic.mk_ge ctx e1' e2'
  
    | LessThan (e1, e2) ->
        let e1' = z3_of_exp ctx sigma iota multi_cfg z3_vars e1 dvar_list called_contracts in
        let e2' = z3_of_exp ctx sigma iota multi_cfg z3_vars e2 dvar_list called_contracts in
        Z3.Arithmetic.mk_lt ctx e1' e2'
  
    | LessThanEqual (e1, e2) ->
        let e1' = z3_of_exp ctx sigma iota multi_cfg z3_vars e1 dvar_list called_contracts in
        let e2' = z3_of_exp ctx sigma iota multi_cfg z3_vars e2 dvar_list called_contracts in
        Z3.Arithmetic.mk_le ctx e1' e2'
  
    | Val (BoolVal b) -> Z3.Boolean.mk_val ctx b
    | Val (IntVal i) -> Z3.Arithmetic.Integer.mk_numeral_i ctx i
    | Val (StrVal s) -> Z3.Seq.mk_string ctx s
    | Val (PtpID s) -> Z3.Seq.mk_string ctx (match s with PID i -> i)
    (* | Val (ListVal s) -> Z3.Boolean.mk_val ctx true
    | Val (MapVal s) -> Z3.Boolean.mk_val ctx true *)
  
    | ListIndex (list_exp, index_exp, default_exp) ->
      let (eval_result, _) = Helper.eval sigma iota (ListIndex (list_exp, index_exp, default_exp)) multi_cfg !called_contracts in
      (match eval_result with
      | IntVal i -> Z3.Arithmetic.Integer.mk_numeral_i ctx i
      | _ -> failwith "Unsupported value type in ListIndex")

    | MapIndex (map_exp, key_exp, default_exp) ->
        let (eval_result, _) = Helper.eval sigma iota (MapIndex (map_exp, key_exp, default_exp)) multi_cfg !called_contracts in
        (match eval_result with
        | IntVal i -> Z3.Arithmetic.Integer.mk_numeral_i ctx i
        | StrVal s -> Z3.Seq.mk_string ctx s
        | BoolVal b -> Z3.Boolean.mk_val ctx b
        | _ -> failwith "Unsupported value type in MapIndex")

    | PtID ptp_var ->
        let (eval_result, _) = Helper.eval sigma iota (PtID ptp_var) multi_cfg !called_contracts in
        (match eval_result with
         | PtpID (PID s) ->
             if not (Hashtbl.mem z3_vars s) then
                 let z3_var = Z3.Seq.mk_string ctx s in
                 Hashtbl.add z3_vars s z3_var;
                 z3_var
             else
                 Hashtbl.find z3_vars s
         | _ -> failwith "Expected participant ID in PtID")
  
      | FuncCall (func_name, args) ->
          let arg_expressions = List.map (fun arg -> z3_of_exp ctx sigma iota multi_cfg z3_vars arg dvar_list called_contracts) args in
          (match func_name with
          | "min" -> 
              Z3.Quantifier.mk_bound ctx (List.length args) (Z3.Arithmetic.Integer.mk_sort ctx) (* Represents min formula *)

          | "max" -> 
              Z3.Quantifier.mk_bound ctx (List.length args) (Z3.Arithmetic.Integer.mk_sort ctx) (* Represents max formula *)

          | "get_amount_out" ->
            (* Formula for get_amount_out *)
            (match arg_expressions with
            | [amountIn; reserveIn; reserveOut; feePercent] ->
                let multiplier = Z3.Arithmetic.Integer.mk_numeral_i ctx 1000 in
                let feeAdjustedAmount = Z3.Arithmetic.mk_mul ctx [amountIn; Z3.Arithmetic.mk_sub ctx [multiplier; feePercent]] in
                let numerator = Z3.Arithmetic.mk_mul ctx [feeAdjustedAmount; reserveOut] in
                let denominator = Z3.Arithmetic.mk_add ctx [Z3.Arithmetic.mk_mul ctx [reserveIn; multiplier]; feeAdjustedAmount] in
                Z3.Arithmetic.mk_div ctx numerator denominator
            | _ -> failwith "get_amount_out requires four integer arguments")
            

      | _ -> 
          (* Default evaluation behavior for other functions *)
          let (eval_result, _) = Helper.eval sigma iota (FuncCall (func_name, args)) multi_cfg !called_contracts in
          (match eval_result with
          | IntVal i -> Z3.Arithmetic.Integer.mk_numeral_i ctx i
          | BoolVal b -> Z3.Boolean.mk_val ctx b
          | StrVal s -> Z3.Seq.mk_string ctx s
          | _ -> failwith "Unsupported result type in FuncCall"))


    | FuncCallEdamRead (edam_name, exp) ->
        let (eval_result, _) = Helper.eval sigma iota (FuncCallEdamRead (edam_name, exp)) multi_cfg !called_contracts in
        (match eval_result with
         | IntVal i -> Z3.Arithmetic.Integer.mk_numeral_i ctx i
         | BoolVal b -> Z3.Boolean.mk_val ctx b
         | StrVal s -> Z3.Seq.mk_string ctx s
         | _ -> failwith "Unsupported result type in FuncCallEdamRead")

  
 (* Convert a FuncCallEdamWrite into a Z3 expression *)
and z3_of_func_write
(ctx : Z3.context) 
(sigma : sigma_type) 
(iota : iota_type) 
(multi_cfg : multi_config) 
(z3_vars : (string, Z3.Expr.expr) Hashtbl.t) 
(call : funcCallEdamWrite) 
(dvar_list: (dvar_type * dvar) list) 
(called_contracts: string list ref) 
: Z3.Expr.expr =
match call with   
    | FuncCallEdamWrite (edam_name, operation, values, participants) ->
        (* Ensure that the contract is not re-entering itself *)
        if List.mem edam_name !called_contracts then
            failwith "Reentrancy detected in FuncCallEdamWrite";
        called_contracts := edam_name :: !called_contracts;

        (* Retrieve the EDAM from the multi configuration *)
        (match Hashtbl.find_opt multi_cfg.edam_map edam_name with
        | Some edam ->
            let config = match Hashtbl.find_opt multi_cfg.config_map edam_name with 
                | Some config -> config 
                | None -> failwith "Config not found in multi_config" 
            in

            (* Find the transition corresponding to (operation) *)
            let matching_transition = 
                List.find_opt 
                    (fun (_, (_, _, _,op, _,  _, _, _, _), _) -> op = operation)
                    edam.transitions 
            in

            (match matching_transition with
            | Some (_, (guard, _, _, _, _, dvar_bindings, _, _, _), _) ->  
                
                (* Apply the recursive replacement to all values *)
                let evaluated_values = List.map (fun v -> replace_dvars (guard_to_z3_exp (v, [])) sigma) values in

                (* Now use the evaluated values to build the dvar map *)
                let dvar_map = build_dvar_map dvar_bindings evaluated_values in

                (* Substitute parameters in the guard expression *)
                let substituted_guard = substitute_params (guard_to_z3_exp guard) dvar_map [] in
                
                (* Process participant updates *)
                
                (* Recursively process nested calls with the CORRECT sigma *)
                let z3_guard = z3_of_z3_exp ctx 
                    config.sigma  
                    iota 
                    multi_cfg 
                    z3_vars 
                    substituted_guard 
                    dvar_list 
                    called_contracts in
                z3_guard

            | None -> failwith "Transition not found for FuncCallEdamWrite")
        | None -> failwith "EDAM not found in multi_config")


let print_z3_expr (expr: Z3.Expr.expr) : unit =
  let expr_str = Z3.Expr.to_string expr in
  Printf.printf "\n\nZ3 Expression: %s\n\n" expr_str


(* Main function to check satisfiability of a guard *)
let check_guard_satisfiability 
  (ctx : Z3.context) 
  (guard : exp) 
  (dvar_list: (dvar_type * dvar) list) 
  (sigma : sigma_type) 
  (iota : iota_type) 
  (multi_cfg : multi_config) 
  : Z3.Solver.status * (string * Z3.Expr.expr) list =

    (* Create a solver instance *)
    let solver = Z3.Solver.mk_solver ctx None in

    (* Mutable hashtable for Z3 variables *)
    let z3_vars = Hashtbl.create 10 in

    (* Reference to track called contracts *)
    let called_contracts = ref [] in

    (* print_endline "\nStarting Z3 conversion"; *)
    (* Convert the guard expression to a Z3 expression *)
    let z3_guard = z3_of_exp ctx sigma iota multi_cfg z3_vars guard dvar_list called_contracts in

    (* print_endline "\nFinished Z3 conversion"; *)
    (* Print Z3 guard expression for debugging *) 
    (* print_z3_expr z3_guard; *)

    (* Add the guard to the solver *)
    Z3.Solver.add solver [z3_guard];

    (* Check for satisfiability *)
    let result = Z3.Solver.check solver [] in

    (* If satisfiable, extract the model *)
    match result with
    | Z3.Solver.SATISFIABLE ->
        let model = Z3.Solver.get_model solver in
        (match model with
         | Some m ->
             let bindings = Hashtbl.fold (fun var expr acc ->
               match Z3.Model.eval m expr true with
               | Some value -> (var, value) :: acc
               | None -> acc
             ) z3_vars [] in
             (Z3.Solver.SATISFIABLE, bindings)
         | None -> (Z3.Solver.SATISFIABLE, []))
    | _ -> (result, [])

    
(* Initialize sigma as a function for variable lookups *)
let sigma : sigma_type = function
  | Var "des" -> StrVal ""
  | _ -> failwith "Unknown Var"

(* Example iota function to return a participant; here, it's a dummy function *)
let iota : iota_type = function
  | Ptp "user" -> PID "participant_1"
  | _ -> failwith "Unknown participant"

(* Example multi_cfg initialization *)
let multi_cfg : multi_config = {
  edam_map = Hashtbl.create 10;
  config_map = Hashtbl.create 10;
}

(* Main function 
let main () =
  let ctx = Z3.mk_context [] in

  let guard = And (GreaterThan (Dvar (Var "X"), Val (IntVal 5)), Equal (Val (IntVal 2), Dvar (Var "Y"))) in
  let guard2 = Not(Dvar (Var "_choice")) in

  let result, model = check_guard_satisfiability ctx guard2 [(Var "bool", Var "_choice")] sigma iota multi_cfg in

  match result with
  | Z3.Solver.SATISFIABLE ->
      Printf.printf "Guard is satisfiable.\n";
      List.iter (fun (var, value) ->
          Printf.printf "%s = %s\n" var (Z3.Expr.to_string value)
        ) model
  | Z3.Solver.UNSATISFIABLE -> Printf.printf "Guard is not satisfiable.\n"
  | Z3.Solver.UNKNOWN -> Printf.printf "Satisfiability unknown.\n"

*)
  

