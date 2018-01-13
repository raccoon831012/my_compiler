%option yylineno
%{
	#include "stdio.h"
	#include "lotus.tab.h"
%}
delim [ \t\n]
ws {delim}+
Command \/\*((\n|.)*)\*\/|\/\/(.*)
letter [A-Za-z]
digit [0-9]
id {letter}({letter}|{digit})*
number {digit}+(\.{digit}+)?(E[+\-]?{digit}+)?
KeyWord int
Operator [=+\-\*\/\|%]
Parentheses [(){}]
Semicolon ;
Read read
Write write
If if
Else else
Exit exit
And &&
Or \|\|
Not !
Greater >
Less <
Equal ==
GEqual >=
LEqual <=
NEqual !=
While while
%%
{Command} {}
{ws} {/*no action*/}
{Read} {return READ;}
{Write} {return WRITE;}
{Exit} {return EXIT;}
{If} {return IF;}
{Else} {return ELSE;}
{While} {return WHILE;}
{KeyWord} {return KEYWORD;}
{number} {yylval.intval = atoi(yytext); return INTEGER;}
{id} {yylval.word = strdup(yytext); return IDENTIFIER;}
{Operator} {return yytext[0];}
{Parentheses} {return yytext[0];}
{Semicolon} {return SEMICOLON;}
{And} {return AND;}
{Or} {return OR;}
{Not} {return NOT;}
{Greater} {return GREATER;}
{Less} {return LESS;}
{Equal} {return EQUAL;}
{GEqual} {return GEqual;}
{LEqual} {return LEqual;}
{NEqual} {return NEqual;}

%%

