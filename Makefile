all: clean build test

build:
	lex jucompiler.l
	cc lex.yy.c -o jucompiler
	./jucompiler < input.txt

test:
	cd tests && ./test.sh ../jucompiler

clean:
	rm -f lex.yy.c jucompiler
