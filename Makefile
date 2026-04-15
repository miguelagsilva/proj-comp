all: clean build test zip

build:
	yacc -d -v -t -g --report=all -Wcounterexamples -Wconflicts-sr jucompiler.y
	lex jucompiler.l
	cc lex.yy.c y.tab.c ast.c semantics.c -o jucompiler -Wall -Wno-unused-function
	./jucompiler < input.txt

test:
	cd tests && ./test.sh ../jucompiler

clean:
	rm -f lex.yy.c jucompiler y.tab.c y.tab.h jucompiler.zip
	rm -rf tests/java/**/*.out_temp

zip:
	zip jucompiler.zip jucompiler.l jucompiler.y ast.c ast.h -r
