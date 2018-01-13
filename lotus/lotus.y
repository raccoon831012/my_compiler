%{
#include <stdio.h>
#include "lotus.tab.h"
#include <string.h>
static int L=1;
static int Lnext=0;
static int tmp = -1;

extern int yylineno;
extern char* yytext;
int yylex();
int yyerror (char const *s){
	 fprintf(stderr,"yyerror line %d: %s %s\n",yylineno,yytext,s);
}

%}
%union{
	int intval;
	char *word;
	int place[3]; //0: true, 1: false, 2: end
}
%token <word> IDENTIFIER
%token <intval> INTEGER
%token  KEYWORD OPERATORS ERROR PARENTHESES SEMICOLON EXIT WHILE
%token READ WRITE
%token AND NOT OR
%token GREATER LESS EQUAL GEqual LEqual NEqual
%token IF ELSE

%type <place> if_statement bool_expression bool_primary bool_factor bool_term while_statement
%type <intval> arith_expression arith_term arith_factor arith_primary whilebegin

%left '-' '+'
%left '*' '/'
%precedence NEG   /* negation--unary minus */

%start program

%%
program: IDENTIFIER '(' ')' function_body
;

function_body: '{'{printf("\t.data\n");} variable_declarations {printf("\t.text\n");printf("\tmain:\n");} statements '}'
;

variable_declarations: KEYWORD variable_declaration variable_declarations
		|/*empty*/
;

variable_declaration: variable_declaration ',' IDENTIFIER  {printf("%s:\n\t.word 0\n",yytext);} SEMICOLON
;

variable_declaration: IDENTIFIER {printf("%s:\n\t.word 0\n",yytext);} SEMICOLON
;

statements: /*empty*/								
	| statements statement	
;

statement: read_statement							
	| if_statement			
	| write_statement							
	| compound_statement							
	| exit_statement							
	| while_statement							
	| assignment_statement							
;

assignment_statement: IDENTIFIER '=' arith_expression SEMICOLON {int s=++tmp; printf("\tla $t%d, %s\n\tsw $t%d, 0($t%d)\n",s,$1,$3,s);tmp = tmp-tmp-1;}
;

compound_statement: '{' statements '}'						
;
while_statement: WHILE whilebegin '(' bool_expression ')' {printf("\tb L%d\n", $4[1]);} {printf("L%d: \n", $4[0]);} statement {printf("\tb L%d #while back\nL%d: #while end\n", $2, $4[1]);}
;

whilebegin: {$$=L++; printf("L%d: #loop begin\n", $$);}
;

exit_statement: EXIT SEMICOLON							{printf("\tli $v0, 10 # Exit\n\tsyscall\n");}
;
read_statement: READ IDENTIFIER	{printf("\tli $v0, 5\n\tsyscall\n\tla $t0, %s\n\tsw $v0, 0($t0)\n",yytext);} SEMICOLON
;

write_statement: WRITE arith_expression SEMICOLON				{printf("\tmove $a0, $t%d # Write\n\tli $v0, 1\n\tsyscall\n", $2);}
;

if_statement: IF '(' bool_expression ')' {printf("\tb L%d\nL%d: \n", $3[1], $3[0]);} statement {printf("\tb L%d #then\n", $3[2]);} ELSE {printf("L%d: #else\n", $3[1]);} statement {printf("L%d: #ifend\n", $3[2]);}
	|  IF '(' bool_expression ')' {printf("\tb L%d\nL%d: \n", $3[2], $3[0]);} statement {printf("L%d: \n", $3[1]);} 
;

bool_expression: bool_term 							{$$[0] = $1[0]; $$[1] = $1[1]; $$[2]=$1[2];}
	| bool_expression OR {printf("L%d: \n", $1[1]);} bool_term		{$$[0] = $1[0]; $$[1] = $4[1]; $$[2]=$1[2];}
;
bool_term: bool_factor 								{$$[0] = $1[0]; $$[1] = $1[1]; $$[2]=$1[2];}
	| bool_term AND {printf("L%d: \n", $1[0]);} bool_factor			{$$[0] = $4[0]; $$[1] = $1[1]; $$[2]=$1[2];}
;
bool_factor: bool_primary 							{$$[0] = $1[0]; $$[1] = $1[1]; $$[2]=$1[2];}
	| NOT bool_primary							{$$[0] = $2[1]; $$[1] = $2[0]; $$[2]=$2[2];}
;

bool_primary: arith_expression EQUAL arith_expression				{$$[0]=L++; $$[1]=L++; $$[2]=L++; printf("\tbeq $t%d, $t%d, L%d\n", $1, $3, $$[0]); tmp=-1;}
	| arith_expression NEqual arith_expression				{$$[0]=L++; $$[1]=L++; $$[2]=L++; printf("\tbne $t%d, $t%d, L%d\n", $1, $3, $$[0]); tmp=-1;}
	| arith_expression GREATER arith_expression				{$$[0]=L++; $$[1]=L++; $$[2]=L++; printf("\tbgt $t%d, $t%d, L%d\n", $1, $3, $$[0]); tmp=-1;}
	| arith_expression GEqual arith_expression				{$$[0]=L++; $$[1]=L++; $$[2]=L++; printf("\tbge $t%d, $t%d, L%d\n", $1, $3, $$[0]); tmp=-1;}
	| arith_expression LESS arith_expression				{$$[0]=L++; $$[1]=L++; $$[2]=L++; printf("\tblt $t%d, $t%d, L%d\n", $1, $3, $$[0]); tmp=-1;}
	| arith_expression LEqual arith_expression				{$$[0]=L++; $$[1]=L++; $$[2]=L++; printf("\tble $t%d, $t%d, L%d\n", $1, $3, $$[0]); tmp=-1;}
;

arith_expression: arith_term 							{$$ = $1;}
	| arith_expression '+' arith_term					{printf("\tadd $t%d, $t%d, $t%d\n", $1, $1, $3); $$=$1;tmp-=$3;}
	| arith_expression '-' arith_term					{printf("\tsub $t%d, $t%d, $t%d\n", $1, $1, $3); $$=$1;tmp-=$3;}
;
arith_term: arith_factor							{$$ = $1;}
	| arith_term '*' arith_factor						{printf("\tmul $t%d, $t%d, $t%d\n", $1, $1, $3); $$=$1;tmp-=$3;}
	| arith_term '/' arith_factor						{printf("\tdiv $t%d, $t%d, $t%d\n", $1, $1, $3); $$=$1;tmp-=$3;}
	| arith_term '%' arith_factor						{printf("\trem $t%d, $t%d, $t%d\n", $1, $1, $3); $$=$1;tmp-=$3;}
;
arith_factor: arith_primary 							{$$ = $1;}
	| '-' arith_primary	%prec NEG					{printf("\tneg $t%d, $t%d\n", $2, $2); $$=$2;}
;
arith_primary: INTEGER	 							{printf("\tli $t%d, %d\n", ++tmp, $1); $$ = tmp;}
	| IDENTIFIER 								{int r=++tmp; printf("\tla $t%d, %s\n\tlw $t%d, 0($t%d)\n", r, $1, r, r); $$=tmp;}
	| '(' arith_expression ')'						{$$ = $2;}
;
%%

int main( int argc, char **argv){

	yyparse();
	return 0;
}

