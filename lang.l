%{
#include <stdio.h>
#include "lang.tab.h"
%}

%option noyywrap
%%
"Vars:" { return VARS; }
"Methods:" { return FUNCS; }
"Constructs:" { return CONSTRUCTS; }
"ENTRY" { return ENTRY; }
"EXIT" { return EXIT; }
"USRDEF" { return USRDEF; }
"GLOBALVAR" { return GLOBALVAR; }
"GLOBALFUNC" { return GLOBALFUNC; }
"main" { return MAIN; }
"fn" { return FNENTRY; }
"return" { return RETURN; }
"if" { return IF; }
"else" { return ELSE; }
"while" { return WHILE; }
"for" { return FOR; }
"switch" { return SWITCH; }
"case" { return CASE; }
"default" {return DEFAULT;}
"<" {return LT;}
">" {return GT;}
"==" { return EQ; }
"!=" { return NEQ; }
">=" { return GEQ; }
"<=" { return LEQ; }
"and" { return AND; }
"or" { return OR; }
"not" { return NOT; }
"true" { yylval.boolean = 1; return BOOL; }
"false" { yylval.boolean = 0; return BOOL; }
"break" { return BREAK; }
"print" { return PRINT; }
"const" { return CONST; }
"TypeOf" { return TYPEOF;}
"Eval" { return EVAL;}
"int"|"float"|"char"|"string"|"bool" {yylval.string = strdup(yytext);return TYPE;}
"class" {yylval.string = strdup(yytext); return CLASS;}
[a-zA-Z][a-zA-Z0-9]* {yylval.string = strdup(yytext); return ID;}
[1-9][0-9]*|0 { yylval.integer = atoi(yytext); return INT; }
([1-9][0-9]*|0)\.[0-9]+ { yylval.floatnum = atof(yytext); return FLOAT; }
\"[^"]*\" { yytext = yytext+1; yytext[strlen(yytext) - 1] = '\0'; yylval.string = strdup(yytext); return STRING; }
\'[^']\' { yylval.character = yytext[1]; return CHAR; }
[ \t] ;
(\r|\n|\r\n) {yylineno++;}
. {return yytext[0];}

%%