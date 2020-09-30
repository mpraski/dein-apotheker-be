%% process.xrl

Definitions.

%% Common lexemes
Whitespace = [\s\t]
Terminator = \n|\r\n|\r
LeftParen = \(
RightParen = \)
LeftBracket = \[
RightBracket = \]
Dot = \.
Comma = ,
Separator = ;
Assign = \=
If = IF
Elif = ELIF
Then = THEN
Else = ELSE
For = FOR
In = IN
Do = DO
With = WITH
And = AND
Or = OR
Equals = \=\=
NotEquals = \!\=
Greater = >
GreaterEqual = >\=
Lower = <
LowerEqual = <\=

%% Data query
All = \*
Select = SELECT
From = FROM
Where = WHERE
Join = JOIN
On = ON

%% Objects
Digit = [0-9]
Binary = [A-Za-z0-9_\.\!\?,\s]
IdentifierStart = [A-Za-z_]
IdentifierRest = [A-Za-z0-9_]

Number = {Digit}+
String = '{Binary}+'
Identifier = {IdentifierStart}{IdentifierRest}*
Variable = {LeftBracket}{Identifier}{RightBracket}

Rules.

{Whitespace} : skip_token.
{Terminator} : skip_token.

{Dot}          : {token, {dot, TokenLine}}.
{Comma}        : {token, {comma, TokenLine}}.
{Separator}    : {token, {sep, TokenLine}}.
{Assign}       : {token, {assign, TokenLine}}.
{If}           : {token, {lif, TokenLine}}.
{Elif}         : {token, {elif, TokenLine}}.
{Then}         : {token, {then, TokenLine}}.
{Else}         : {token, {else, TokenLine}}.
{For}          : {token, {for, TokenLine}}.
{In}           : {token, {in, TokenLine}}.
{Do}           : {token, {do, TokenLine}}.
{With}         : {token, {with, TokenLine}}.
{And}          : {token, {land, TokenLine}}.
{Or}           : {token, {lor, TokenLine}}.
{Equals}       : {token, {equals, TokenLine}}.
{Greater}      : {token, {greater, TokenLine}}.
{GreaterEqual} : {token, {greater_equal, TokenLine}}.
{Lower}        : {token, {lower, TokenLine}}.
{LowerEqual}   : {token, {lower_equal, TokenLine}}.
{NotEquals}    : {token, {not_equals, TokenLine}}.
{LeftParen}    : {token, {left_paren, TokenLine}}.
{RightParen}   : {token, {right_paren, TokenLine}}.
{All}          : {token, {all, TokenLine}}.
{Select}       : {token, {select, TokenLine}}.
{From}         : {token, {from, TokenLine}}.
{Where}        : {token, {where, TokenLine}}.
{Join}         : {token, {join, TokenLine}}.
{On}           : {token, {on, TokenLine}}.

{Number}     : {token, {num, TokenLine, trim_num(TokenChars)}}.
{String}     : {token, {str, TokenLine, trim_str(TokenChars)}}.
{Variable}   : {token, {var, TokenLine, trim_var(TokenChars)}}.
{Identifier} : {token, {ident, TokenLine, list_to_atom(TokenChars)}}.

Erlang code.

trim_var(Var) ->
    list_to_atom(string:trim(Var, both, "[]")).

trim_str(Var) ->
    string:trim(Var, both, "'").

trim_num(Var) ->
    list_to_integer(Var).