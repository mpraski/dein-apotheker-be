%% process.yrl

Nonterminals
comp_op logical_op identifier variable variable_list program stmt expr if_stmt unless_stmt for_stmt logical_expr comp_expr function_expr arg_expr.

Terminals
comma sep lif unless then else for in do with land lor equals not_equals left_paren right_paren ident var.

Rootsymbol program.

program -> stmt             : ['$1'].
program -> stmt sep program : ['$1'|'$3'].

stmt -> if_stmt       : '$1'.
stmt -> unless_stmt   : '$1'.
stmt -> for_stmt      : '$1'.
stmt -> function_expr : '$1'.

if_stmt -> lif expr then program else program : {action('$1'), '$2', '$4', '$6'}.

unless_stmt -> unless expr then program else program : {action('$1'), '$2', '$4', '$6'}.

for_stmt -> for variable in variable do program : {action('$1'), '$2', '$4', '$6'}.

expr -> variable      : '$1'.
expr -> logical_expr  : '$1'.
expr -> comp_expr     : '$1'.
expr -> function_expr : '$1'.

logical_expr -> left_paren expr logical_op expr right_paren : {'$3', '$2', '$4'}.

comp_expr -> variable comp_op identifier : {'$2', '$1', '$3'}.

function_expr -> identifier left_paren right_paren          : {call, '$1', {nil, nil}}.
function_expr -> identifier left_paren arg_expr right_paren : {call, '$1', '$3'}.

arg_expr -> identifier                   : {'$1', []  }.
arg_expr -> identifier with variable_list: {'$1', '$3'}.

variable_list -> variable                     : ['$1'].
variable_list -> variable comma variable_list : ['$1'|'$3'].

comp_op -> equals     : action('$1').
comp_op -> not_equals : action('$1').

logical_op -> lor  : action('$1').
logical_op -> land : action('$1').

identifier -> ident : unwrap('$1').

variable -> var : unwrap('$1').

Erlang code.

action({A,_}) -> A.

unwrap({_,_,V}) -> V.