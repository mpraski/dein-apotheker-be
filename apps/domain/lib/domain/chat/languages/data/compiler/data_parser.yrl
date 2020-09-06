%% data.yrl

Nonterminals
logical_op database argument column variable column_list select_list select_stmt where_stmt stmt program.

Terminals
comma all select from where equals not_equals ident var.

Rootsymbol program.

program -> stmt : '$1'.

stmt -> select_stmt : '$1'.

select_stmt -> select select_list from database                 : {action('$1'), '$2', '$4'}.
select_stmt -> select select_list from database where where_stmt: {action('$1'), '$2', '$4', '$6'}.

select_list -> all         : action('$1').
select_list -> column_list : '$1'.

column_list -> column                   : ['$1'].
column_list -> column comma column_list : ['$1'|'$3'].

where_stmt -> column logical_op variable     : {'$2', '$1', {var, '$3'}}.
where_stmt -> column logical_op argument     : {'$2', '$1', {lit, '$3'}}.

logical_op -> equals     : action('$1').
logical_op -> not_equals : action('$1').

argument -> ident : unwrap('$1').

column -> ident : unwrap('$1').

variable -> var : unwrap('$1').

database -> ident : unwrap('$1').

Erlang code.

action({A,_}) -> A.

unwrap({_,_,V}) -> V.