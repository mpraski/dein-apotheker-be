%% data.yrl

Nonterminals
logical_op identifier string variable column_list select_list select_stmt where_stmt stmt program.

Terminals
comma all select from where equals not_equals ident var str.

Rootsymbol program.

program -> stmt : '$1'.

stmt -> select_stmt : '$1'.

select_stmt -> select select_list from identifier                  : {action('$1'), '$2', '$4'}.
select_stmt -> select select_list from identifier where where_stmt : {action('$1'), '$2', '$4', '$6'}.

select_list -> all         : action('$1').
select_list -> column_list : '$1'.

column_list -> identifier                   : ['$1'].
column_list -> identifier comma column_list : ['$1'|'$3'].

where_stmt -> identifier logical_op variable : {'$2', '$1', {var, '$3'}}.
where_stmt -> identifier logical_op string   : {'$2', '$1', {str, '$3'}}.

logical_op -> equals     : action('$1').
logical_op -> not_equals : action('$1').

identifier -> ident : unwrap('$1').

variable -> var : unwrap_none('$1').

string -> str : unwrap_text('$1').

Erlang code.

action({A,_}) -> A.

unwrap_none({_,_,V}) -> V.

unwrap_text({_,_,V}) -> list_to_binary(V).

unwrap({_,_,V}) -> list_to_atom(V).
