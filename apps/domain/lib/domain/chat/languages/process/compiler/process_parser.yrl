%% process.yrl

Nonterminals
comp_op logical_op identifier variable variable_list program stmt stmts stmts_paren expr if_stmt unless_stmt for_stmt logical_expr comp_expr function_expr expr_list.

Terminals
comma sep lif unless then else for in do with land lor equals not_equals left_paren right_paren ident var.

Rootsymbol program.

program -> stmts : '$1'.

stmts_paren -> stmt                         : '$1'.
stmts_paren -> left_paren stmts right_paren : '$2'.

stmts -> stmt           : ['$1'].
stmts -> stmt sep stmts : ['$1'|'$3'].

stmt -> if_stmt       : '$1'.
stmt -> unless_stmt   : '$1'.
stmt -> for_stmt      : '$1'.
stmt -> function_expr : '$1'.

if_stmt -> lif expr then stmts_paren else stmts_paren : {action('$1'), '$2', '$4', '$6'}.

unless_stmt -> unless expr then stmts_paren else stmts_paren : {action('$1'), '$2', '$4', '$6'}.

for_stmt -> for variable in variable do stmts_paren : {action('$1'), '$2', '$4', '$6'}.

expr -> identifier                                           : '$1'.
expr -> identifier with left_paren variable_list right_paren : {with, '$1', '$3'}.
expr -> variable                                             : '$1'.
expr -> logical_expr                                         : '$1'.
expr -> comp_expr                                            : '$1'.
expr -> function_expr                                        : '$1'.

expr_list -> expr                 : ['$1'].
expr_list -> expr comma expr_list : ['$1'|'$3'].

logical_expr -> left_paren expr logical_op expr right_paren : {'$3', '$2', '$4'}.

comp_expr -> variable comp_op identifier : {'$2', '$1', '$3'}.

function_expr -> identifier left_paren right_paren           : {call, '$1', []  }.
function_expr -> identifier left_paren expr_list right_paren : {call, '$1', '$3'}.

variable_list -> variable                     : ['$1'].
variable_list -> variable comma variable_list : ['$1'|'$3'].

comp_op -> equals     : action('$1').
comp_op -> not_equals : action('$1').

logical_op -> lor  : action('$1').
logical_op -> land : action('$1').

identifier -> ident : {ident, unwrap('$1')}.

variable -> var : {var, unwrap('$1')}.

Erlang code.

action({A,_}) -> A.

unwrap({_,_,V}) -> V.