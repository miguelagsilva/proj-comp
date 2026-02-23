all: 
	lex jucompiler.l
	cc lex.yy.c -o jucompiler
	./jucompiler < input.txt
