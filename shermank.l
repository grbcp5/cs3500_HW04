%{

%}

WSPACE	[ \t\r]+
NEWLINE	\n
LETTER	[a-zA-Z]
DIGIT	[0-9]
IDENT	(_|{LETTER})({LETTER}|{DIGIT}|_)*
INTCONST	(\+|-)?{DIGIT}+
STRCONST	\".*\"
COMMENT	;.*

%%
"let*" {
	printTokenInfo("LETSTAR", yytext);
	startScope();
	return T_LETSTAR;
}

"lambda" {	
	printTokenInfo("LAMBDA", yytext);
	startScope();
	return T_LAMBDA;
}

"input" {
	printTokenInfo("INPUT", yytext);
	return T_INPUT;
}

"print" {
	printTokenInfo("PRINT", yytext);
	return T_PRINT;
}

"if" {
	printTokenInfo("IF", yytext);
	return T_IF;
}

"(" {
	printTokenInfo("LPAREN", yytext);
	return T_LPAREN;
}

")" {
	printTokenInfo("RPAREN", yytext);
	return T_RPAREN;
}

"+" {
	printTokenInfo("ADD", yytext);
	return T_ADD;
}

"*" {
	printTokenInfo("MULT", yytext);
	return T_MULT;
}

"/" {
	printTokenInfo("DIV", yytext);
	return T_DIV;
}

"-" {
	printTokenInfo("SUB", yytext);
	return T_SUB;
}

"and" {
	printTokenInfo("AND", yytext);
	return T_AND;
}

"or" {
	printTokenInfo("OR", yytext);
	return T_OR;
}

"not" {
	printTokenInfo("NOT", yytext);
	return T_NOT;
}

"<" {
	printTokenInfo("LT", yytext);
	return T_LT;
}

">" {
	printTokenInfo("GT", yytext);
	return T_GT;
}

"<=" {
	printTokenInfo("LE", yytext);
	return T_LE;
}

">=" {
	printTokenInfo("GE", yytext);
	return T_GE;
}

"=" {
	printTokenInfo("EQ", yytext);
	return T_EQ;
}

"/=" {
	printTokenInfo("NE", yytext);
	return T_NE;
}

"t" {
	printTokenInfo("T", yytext);
	return T_T;
}

"nil" {
	printTokenInfo("NIL", yytext);
	return T_NIL;
}

{IDENT} {
	yylval.text = strdup(yytext);
	printTokenInfo("IDENT", yytext);
	return T_IDENT;
}

{INTCONST} {
	printTokenInfo("INTCONST", yytext);
	return T_INTCONST;
}

{STRCONST} {
	printTokenInfo("STRCONST", yytext);
	return T_STRCONST;
}

{NEWLINE} {
	lineNum++;
}

{WSPACE} { }
{COMMENT} { }
. {
	printTokenInfo("UNKNOWN", yytext);
	return T_UNKNOWN;
}

%%
