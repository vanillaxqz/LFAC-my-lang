#!/bin/bash
rm -f lex.yy.c $1.tab.c $1 
bison -d -Wcounterexamples $1.y
lex $1.l
g++ lang.h $1.tab.c lex.yy.c -std=c++11 -o $1
