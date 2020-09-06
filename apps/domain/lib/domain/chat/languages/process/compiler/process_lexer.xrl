%% process.xrl

Definitions.

Whitespace = [\s\t]
Terminator = \n|\r\n|\r
LeftParen = \(
RightParen = \)
LeftBracket = \[
RightBracket = \]
Comma = ,
Separator = ;
If = IF
Unless = UNLESS
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

Identifier = [A-Za-z0-9_]+
Variable = {LeftBracket}{Identifier}{RightBracket}

Rules.

{Whitespace} : skip_token.
{Terminator} : skip_token.

{Comma}      : {token, {comma, TokenLine}}.
{Separator}  : {token, {sep, TokenLine}}.
{If}         : {token, {lif, TokenLine}}.
{Unless}     : {token, {unless, TokenLine}}.
{Then}       : {token, {then, TokenLine}}.
{Else}       : {token, {else, TokenLine}}.
{For}        : {token, {for, TokenLine}}.
{In}         : {token, {in, TokenLine}}.
{Do}         : {token, {do, TokenLine}}.
{With}       : {token, {with, TokenLine}}.
{And}        : {token, {land, TokenLine}}.
{Or}         : {token, {lor, TokenLine}}.
{Equals}     : {token, {equals, TokenLine}}.
{NotEquals}  : {token, {not_equals, TokenLine}}.
{LeftParen}  : {token, {left_paren, TokenLine}}.
{RightParen} : {token, {right_paren, TokenLine}}.

{Identifier} : {token, {ident, TokenLine, list_to_atom(TokenChars)}}.
{Variable}   : {token, {var, TokenLine, trim_var(TokenChars)}}.

Erlang code.

trim_var(Var) ->
    list_to_atom(string:trim(Var, both, "[]")).