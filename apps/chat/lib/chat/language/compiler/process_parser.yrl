Header "%% Copyright (C)"
"%% @private"
"%% @Author Marcin Praski".

Nonterminals
stmt stmt_list expr assign_stmt if_stmt elif_stmt 
for_stmt list_expr function_expr arg_list pattern_match_expr
select_expr where_expr on_expr join_expr join_expr_list select_list 
column_list qualified_database maybe_qualified_database identifier 
qualified_identifier maybe_qualified_identifier variable string 
number column eq_op comp_op logical_op additive_op multiplicative_op in_op.

Terminals
dot sep comma assign lif elif then else for in do 
lend land lor equals not_equals greater greater_equal 
lower lower_equal left_paren right_paren ident 
left_angle right_angle var str num all select 
from where join on plus minus divides.

Rootsymbol stmt_list.

Right 100 assign.
Left 300 logical_op in_op.
Left 400 comp_op.
Nonassoc 500 eq_op.
Left 600 additive_op.
Left 700 multiplicative_op.

Expect 1.

stmt_list -> stmt               : ['$1'].
stmt_list -> stmt sep           : ['$1'].
stmt_list -> stmt sep stmt_list : ['$1'|'$3'].

stmt -> expr        : '$1'.
stmt -> if_stmt     : '$1'.
stmt -> for_stmt    : '$1'.
stmt -> assign_stmt : '$1'.

expr -> identifier                  : '$1'.
expr -> variable                    : '$1'.
expr -> string                      : '$1'.
expr -> number                      : '$1'.
expr -> list_expr                   : '$1'.
expr -> select_expr                 : '$1'.
expr -> function_expr               : '$1'.
expr -> expr eq_op             expr : {'$2', '$1', '$3'}.
expr -> expr comp_op           expr : {'$2', '$1', '$3'}.
expr -> expr logical_op        expr : {'$2', '$1', '$3'}.
expr -> expr additive_op       expr : {'$2', '$1', '$3'}.
expr -> expr multiplicative_op expr : {'$2', '$1', '$3'}.
expr -> left_paren expr right_paren : '$2'.

arg_list -> expr                : ['$1'].
arg_list -> expr comma arg_list : ['$1'|'$3'].

list_expr -> left_angle                       right_angle : {list, [] }.
list_expr -> left_angle number dot dot number right_angle : {list, '$2','$5'}.
list_expr -> left_angle arg_list              right_angle : {list, '$2' }.

function_expr -> identifier left_paren          right_paren : {call, '$1', []  }.
function_expr -> identifier left_paren arg_list right_paren : {call, '$1', '$3'}.

pattern_match_expr -> identifier : '$1'.
pattern_match_expr -> list_expr  : '$1'.

assign_stmt -> pattern_match_expr assign expr : {action('$2'), '$1', '$3'}.

if_stmt -> lif expr then stmt_list           lend           : {lif, [{'$2', '$4'}       ], []}.
if_stmt -> lif expr then stmt_list           else stmt_list : {lif, [{'$2', '$4'}       ], '$6'}.
if_stmt -> lif expr then stmt_list elif_stmt else stmt_list : {lif, [{'$2', '$4'} | '$5'], '$7'}.

elif_stmt -> elif expr then stmt_list           : [{'$2', '$4'}     ].
elif_stmt -> elif expr then stmt_list elif_stmt : [{'$2', '$4'} | '$5'].

for_stmt -> for identifier in expr do stmt_list lend : {action('$1'), '$2', '$4', '$6'}.

select_expr -> select select_list from maybe_qualified_database                                 : {action('$1'), '$2', '$4',   [],  nil}.
select_expr -> select select_list from maybe_qualified_database                where where_expr : {action('$1'), '$2', '$4',   [], '$6'}.
select_expr -> select select_list from maybe_qualified_database join_expr_list                  : {action('$1'), '$2', '$4', '$5',  nil}.
select_expr -> select select_list from maybe_qualified_database join_expr_list where where_expr : {action('$1'), '$2', '$4', '$5', '$7'}.

where_expr -> maybe_qualified_identifier eq_op expr : {'$2', '$1', '$3'}.
where_expr -> maybe_qualified_identifier in_op expr : {'$2', '$1', '$3'}.
where_expr -> where_expr logical_op where_expr      : {'$2', '$1', '$3'}.
where_expr -> left_paren where_expr right_paren     : '$2'.

on_expr -> qualified_identifier eq_op qualified_identifier : {'$2', '$1', '$3'}.
on_expr -> on_expr logical_op on_expr                      : {'$2', '$1', '$3'}.

join_expr -> join qualified_database on on_expr : {action('$1'), '$2', '$4'}.

join_expr_list -> join_expr                : ['$1'].
join_expr_list -> join_expr join_expr_list : ['$1'|'$2'].

select_list -> all         : action('$1').
select_list -> column_list : '$1'.

column -> maybe_qualified_identifier : '$1'.
column -> variable                   : '$1'.

column_list -> column                   : ['$1'].
column_list -> column comma column_list : ['$1'|'$3'].

qualified_database -> identifier identifier : {qualified_db, '$1', '$2'}.

maybe_qualified_database -> identifier            : '$1'.
maybe_qualified_database -> identifier identifier : {qualified_db, '$1', '$2'}.

string -> str : {string, unwrap('$1')}.

number -> num : {number, unwrap('$1')}.

variable -> var : {var, unwrap('$1')}.

identifier -> ident : {ident, unwrap('$1')}.

qualified_identifier -> identifier dot identifier : {qualified_ident, '$1', '$3'}.

maybe_qualified_identifier -> identifier                : '$1'.
maybe_qualified_identifier -> identifier dot identifier : {qualified_ident, '$1', '$3'}.

in_op -> in : action('$1').

eq_op -> equals     : action('$1').
eq_op -> not_equals : action('$1').

comp_op -> greater       : action('$1').
comp_op -> greater_equal : action('$1').
comp_op -> lower         : action('$1').
comp_op -> lower_equal   : action('$1').

logical_op -> lor  : action('$1').
logical_op -> land : action('$1').

additive_op -> plus  : action('$1').
additive_op -> minus : action('$1').

multiplicative_op -> all     : action('$1').
multiplicative_op -> divides : action('$1').

Erlang code.

action({A,_}) -> A.

unwrap({_,_,V}) -> V.