all: clean build test

build:
	yacc -d -v -t -g --report=all jucompiler.y
	lex jucompiler.l
	cc lex.yy.c y.tab.c ast.c -o jucompiler -Wall -Wno-unused-function
	./jucompiler < input.txt

test:
	cd tests && ./test.sh ../jucompiler

clean:
	rm -f lex.yy.c jucompiler y.tab.c y.tab.h
	rm -rf tests/java/**/*.out_temp

zip:
	zip jucompiler.zip jucompiler.l jucompiler.y ast.c ast.h y.tab.c -r
