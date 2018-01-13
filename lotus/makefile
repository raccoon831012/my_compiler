OBJ = lotus.tab.o lex.yy.o

scanner: $(OBJ)
	gcc -o lotus $(OBJ) -lfl
lex.yy.o: lex.yy.c lotus.tab.h
	gcc -c lex.yy.c
lex.yy.c: lotus.l lotus.tab.h
	flex lotus.l
lotus.tab.o: lotus.tab.c lotus.tab.h
	gcc -c lotus.tab.c
lotus.tab.c: lotus.y
	bison -d lotus.y

clean:
	rm -f lex.yy.c lotus.tab.c lotus.tab.h
