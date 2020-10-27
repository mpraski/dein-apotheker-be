%% process.yrl

Nonterminals
expr_list exprs_paren expr decl_expr if_expr elif_expr 
for_expr logical_expr comp_expr function_expr select_expr 
where_expr on_expr join_expr join_expr_list select_list column_list 
qualified_database maybe_qualified_database eq_op comp_op logical_op 
identifier qualified_identifier maybe_qualified_identifier
variable string number column in_op.

Terminals
dot comma assign lif elif then else for in do 
land lor equals not_equals greater greater_equal 
lower lower_equal left_paren right_paren ident 
var str num all select from where join on.

Rootsymbol expr_list.

expr_list -> expr                 : ['$1'].
expr_list -> expr comma expr_list : ['$1'|'$3'].

exprs_paren -> expr                             : ['$1'].
exprs_paren -> left_paren expr_list right_paren :  '$2'.

expr -> logical_expr  : '$1'.
expr -> comp_expr     : '$1'.
expr -> function_expr : '$1'.
expr -> decl_expr     : '$1'.
expr -> if_expr       : '$1'.
expr -> for_expr      : '$1'.
expr -> select_expr   : '$1'.
expr -> identifier    : '$1'.
expr -> variable      : '$1'.
expr -> string        : '$1'.
expr -> number        : '$1'.

logical_expr -> left_paren expr logical_op expr right_paren : {'$3', '$2', '$4'}.

comp_expr -> left_paren expr comp_op expr right_paren : {'$3', '$2', '$4'}.

function_expr -> identifier left_paren           right_paren : {call, '$1', []  }.
function_expr -> identifier left_paren expr_list right_paren : {call, '$1', '$3'}.

decl_expr -> identifier assign expr : {action('$2'), '$1', '$3'}.

if_expr -> lif expr then exprs_paren           else exprs_paren : {lif, [{'$2', '$4'}       ], '$6'}.
if_expr -> lif expr then exprs_paren elif_expr else exprs_paren : {lif, [{'$2', '$4'} | '$5'], '$7'}.

elif_expr -> elif expr then exprs_paren           : [{'$2', '$4'}     ].
elif_expr -> elif expr then exprs_paren elif_expr : [{'$2', '$4'} | '$5'].

for_expr -> for identifier in expr do exprs_paren : {action('$1'), '$2', '$4', '$6'}.

select_expr -> select select_list from maybe_qualified_database                                 : {action('$1'), '$2', '$4',   [],  nil}.
select_expr -> select select_list from maybe_qualified_database                where where_expr : {action('$1'), '$2', '$4',   [], '$6'}.
select_expr -> select select_list from maybe_qualified_database join_expr_list                  : {action('$1'), '$2', '$4', '$5',  nil}.
select_expr -> select select_list from maybe_qualified_database join_expr_list where where_expr : {action('$1'), '$2', '$4', '$5', '$7'}.

where_expr -> maybe_qualified_identifier eq_op number                 : {'$2', '$1', '$3'}.
where_expr -> maybe_qualified_identifier eq_op string                 : {'$2', '$1', '$3'}.
where_expr -> maybe_qualified_identifier eq_op variable               : {'$2', '$1', '$3'}.
where_expr -> maybe_qualified_identifier in_op expr                   : {'$2', '$1', '$3'}.
where_expr -> left_paren where_expr logical_op where_expr right_paren : {'$3', '$2', '$4'}.

on_expr -> qualified_identifier eq_op qualified_identifier   : {'$2', '$1', '$3'}.
on_expr -> left_paren on_expr logical_op on_expr right_paren : {'$3', '$2', '$4'}.

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

eq_op -> equals     : action('$1').
eq_op -> not_equals : action('$1').

in_op -> in : action('$1').

comp_op -> equals        : action('$1').
comp_op -> not_equals    : action('$1').
comp_op -> greater       : action('$1').
comp_op -> greater_equal : action('$1').
comp_op -> lower         : action('$1').
comp_op -> lower_equal   : action('$1').

logical_op -> lor  : action('$1').
logical_op -> land : action('$1').

Erlang code.

action({A,_}) -> A.

unwrap({_,_,V}) -> V.