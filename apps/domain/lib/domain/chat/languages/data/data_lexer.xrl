%% data.xrl

Definitions.

Whitespace = [\s\t]
Terminator = \n|\r\n|\r
LeftBracket = \[
RightBracket = \]
Comma = ,
All = \*
Select = SELECT
From = FROM
Where = WHERE
Equals = \=\=
NotEquals = \!\=

Identifier = [A-Za-z0-9]+
Variable = {LeftBracket}{Identifier}{RightBracket}

Rules.

{Whitespace} : skip_token.
{Terminator} : skip_token.

{Comma}      : {token, {comma, TokenLine}}.
{All}        : {token, {all, TokenLine}}.
{Select}     : {token, {select, TokenLine}}.
{From}       : {token, {from, TokenLine}}.
{Where}      : {token, {where, TokenLine}}.
{Equals}     : {token, {equals, TokenLine}}.
{NotEquals}  : {token, {not_equals, TokenLine}}.

{Identifier} : {token, {ident, TokenLine, list_to_atom(TokenChars)}}.
{Variable}   : {token, {var, TokenLine, trim_var(TokenChars)}}.

Erlang code.

trim_var(Var) ->
    list_to_atom(string:trim(Var, both, "[]")).