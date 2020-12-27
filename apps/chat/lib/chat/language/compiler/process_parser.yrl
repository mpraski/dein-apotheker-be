%% process.yrl

Nonterminals
expr simple_expr decl_expr if_expr elif_expr 
for_expr function_expr expr_list arg_list select_expr 
where_expr on_expr join_expr join_expr_list select_list column_list 
qualified_database maybe_qualified_database identifier 
qualified_identifier maybe_qualified_identifier variable 
string number column eq_op comp_op logical_op in_op.

Terminals
dot sep comma assign lif elif then else for in do 
land lor equals not_equals greater greater_equal 
lower lower_equal left_paren right_paren ident 
var str num all select from where join on.

Rootsymbol expr_list.

Right 100 assign.
Left 300 logical_op in_op.
Left 400 comp_op.
Nonassoc 500 eq_op.

expr_list -> expr               : ['$1'].
expr_list -> expr sep           : ['$1'].
expr_list -> expr sep expr_list : ['$1'|'$3'].

expr -> simple_expr : '$1'.
expr -> decl_expr   : '$1'.
expr -> if_expr     : '$1'.
expr -> for_expr    : '$1'.
expr -> select_expr : '$1'.

simple_expr -> identifier                          : '$1'.
simple_expr -> variable                            : '$1'.
simple_expr -> string                              : '$1'.
simple_expr -> number                              : '$1'.
simple_expr -> function_expr                       : '$1'.
simple_expr -> simple_expr eq_op       simple_expr : {'$2', '$1', '$3'}.
simple_expr -> simple_expr comp_op     simple_expr : {'$2', '$1', '$3'}.
simple_expr -> simple_expr logical_op  simple_expr : {'$2', '$1', '$3'}.
simple_expr -> left_paren  simple_expr right_paren : '$2'.

arg_list -> expr                : ['$1'].
arg_list -> expr comma arg_list : ['$1'|'$3'].

function_expr -> identifier left_paren          right_paren : {call, '$1', []  }.
function_expr -> identifier left_paren arg_list right_paren : {call, '$1', '$3'}.

decl_expr -> identifier assign expr : {action('$2'), '$1', '$3'}.

if_expr -> lif expr then expr_list           else expr_list : {lif, [{'$2', '$4'}       ], '$6'}.
if_expr -> lif expr then expr_list elif_expr else expr_list : {lif, [{'$2', '$4'} | '$5'], '$7'}.

elif_expr -> elif expr then expr_list           : [{'$2', '$4'}     ].
elif_expr -> elif expr then expr_list elif_expr : [{'$2', '$4'} | '$5'].

for_expr -> for identifier in expr do expr_list : {action('$1'), '$2', '$4', '$6'}.

select_expr -> select select_list from maybe_qualified_database                                 : {action('$1'), '$2', '$4',   [],  nil}.
select_expr -> select select_list from maybe_qualified_database                where where_expr : {action('$1'), '$2', '$4',   [], '$6'}.
select_expr -> select select_list from maybe_qualified_database join_expr_list                  : {action('$1'), '$2', '$4', '$5',  nil}.
select_expr -> select select_list from maybe_qualified_database join_expr_list where where_expr : {action('$1'), '$2', '$4', '$5', '$7'}.

where_expr -> maybe_qualified_identifier eq_op simple_expr : {'$2', '$1', '$3'}.
where_expr -> maybe_qualified_identifier in_op simple_expr : {'$2', '$1', '$3'}.
where_expr -> where_expr logical_op where_expr             : {'$2', '$1', '$3'}.
where_expr -> left_paren where_expr right_paren            : '$2'.

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

Erlang code.

action({A,_}) -> A.

unwrap({_,_,V}) -> V.