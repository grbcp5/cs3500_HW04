%{
#include <stdio.h>
#include <iostream>
#include <stack>
#include "SymbolTable.h"
#include "SymbolTableEntry.h"


//These are defined in a way so that a bitwise OR can be applied between 
//them and get the correct associated type. 
#define NA -1
#define INT 1
#define STR 2
#define BOOL 4
#define FUNC 8

#define TYPE_ARITH_OP 0
#define TYPE_LOG_OP 1
#define TYPE_REL_OP 2

int lineNum = 1;

void printRule(const char* lhs, const char* rhs);
int yyerror(const char* s);
void printTokenInfo(const char* tokenType, const char* lexeme);

void startScope();
void endScope();

bool findEntryInAnyScope(const string ident);
void addToScope(const SYMBOL_TABLE_ENTRY entry);

SYMBOL_TABLE_ENTRY * getEntryOfIdent( string ident );

stack<SYMBOL_TABLE> scopeStack;

typedef struct {
  int len;
  int type;
} LIST;

typedef struct {
  int opType;
} BIN_OP_TYPE;

extern "C" {
  int yyparse(void);
  int yylex(void);
  int yywrap() { return 1; }
}

%} 

%union {
  char* text;
  TYPE_INFO typeInfo;
  LIST list;
  BIN_OP_TYPE binOpType;
}

%type <text> T_IDENT
%type <typeInfo> N_CONST 
%type <typeInfo> N_EXPR 
%type <typeInfo> N_PARENTHESIZED_EXPR 
%type <typeInfo> N_IF_EXPR
%type <typeInfo> N_ARITHLOGIC_EXPR
%type <typeInfo> N_LAMBDA_EXPR
%type <typeInfo> N_PRINT_EXPR
%type <typeInfo> N_INPUT_EXPR
%type <typeInfo> N_LET_EXPR
%type <list> N_ID_LIST
%type <list> N_EXPR_LIST
%type <binOpType> N_BIN_OP

%token T_LETSTAR T_LAMBDA T_INPUT T_PRINT T_IF T_LPAREN T_RPAREN T_ADD
%token T_MULT T_DIV T_SUB T_AND T_OR T_NOT T_LT T_GT T_LE T_GE T_EQ
%token T_NE T_T T_NIL T_IDENT T_INTCONST T_STRCONST T_UNKNOWN

%start N_START

%%
N_START : N_EXPR {
  printRule("START", "EXPR");
  printf("\n---- Completed parsing ----\n\n");
  return 0;
};

N_EXPR : N_CONST {
  printRule("EXPR", "CONST");

  $$.type = $1.type;
  $$.numParameters = $1.numParameters;
  $$.returnType = $1.returnType;

} | T_IDENT {
  string identifier;
  bool idFound;
  SYMBOL_TABLE_ENTRY * entry;

  printRule("EXPR", "IDENT");
  identifier = string( $1 );
  idFound = findEntryInAnyScope(identifier);
  if(!idFound) {
    yyerror("Undefined identifier");
    return 1;
  }

  

  entry = getEntryOfIdent( identifier );
  $$.type = entry->getTypeCode();
  $$.numParameters = entry->getTypeInfo().numParameters;
  $$.returnType = entry->getTypeInfo().returnType;

} | T_LPAREN N_PARENTHESIZED_EXPR T_RPAREN {
  printRule("EXPR", "( PARENTHESIZED_EXPR )");

  $$.type = $2.type;
  $$.numParameters = $2.numParameters;
  $$.returnType = $2.returnType;
};

N_CONST : T_INTCONST {
  printRule("CONST", "INTCONST");

  $$.type = INT;
  $$.numParameters = NA;
  $$.returnType = NA;

} | T_STRCONST {
  printRule("CONST", "STRCONST");

  $$.type = STR;
  $$.numParameters = NA;
  $$.returnType = NA;


} | T_T {
  printRule("CONST", "t");

  $$.type = BOOL;
  $$.numParameters = NA;
  $$.returnType = NA;

} | T_NIL {
  printRule("CONST", "nil");

  $$.type = BOOL;
  $$.numParameters = NA;
  $$.returnType = NA;

};

N_PARENTHESIZED_EXPR : N_ARITHLOGIC_EXPR {
  printRule("PARENTHESIZED_EXPR", "ARITHLOGIC_EXPR");

  if( $1.returnType != NA )
    $$.type = $1.returnType;
  else {
    $$.type = $1.type;
    $$.type &= ~(1 << 3);
  }


} | N_IF_EXPR {
  printRule("PARENTHESIZED_EXPR", "IF_EXPR");

  $$.type = $1.type;
  $$.numParameters = NA;
  $$.returnType = NA;

} | N_LET_EXPR {
  printRule("PARENTHESIZED_EXPR", "LET_EXPR");

  $$.type = $1.type;
  $$.numParameters = NA;
  $$.returnType = NA;

} | N_LAMBDA_EXPR {
  printRule("PARENTHESIZED_EXPR", "LAMBDA_EXPR");

  $$.type = $1.type;
  $$.numParameters = $1.numParameters;
  $$.returnType = $1.returnType;

} | N_PRINT_EXPR {
  printRule("PARENTHESIZED_EXPR", "PRINT_EXPR");

  $$.type = $1.type;
  $$.numParameters = $1.numParameters;
  $$.returnType = $1.returnType;

} | N_INPUT_EXPR {
  printRule("PARENTHESIZED_EXPR", "INPUT_EXPR");

  $$.type = $1.type;
  $$.numParameters = $1.numParameters;
  $$.returnType = $1.returnType;

} | N_EXPR_LIST {
  printRule("PARENTHESIZED_EXPR", "EXPR_LIST");
};

N_ARITHLOGIC_EXPR : N_UN_OP N_EXPR {
  printRule("ARITHLOGIC_EXPR", "UN_OP EXPR");

  TYPE_INFO exprTypeInfo = $2;

  if( exprTypeInfo.type & FUNC ) {
    yyerror( "Arg 1 cannot be function" );
    return 1;
  }

  $$.type = BOOL;


} | N_BIN_OP N_EXPR N_EXPR {
  printRule("ARITHLOGIC_EXPR", "BIN_OP EXPR EXPR");

  int binOpType = $1.opType;

  switch( binOpType ) {
    case TYPE_ARITH_OP:
      $$.type = INT;
      
      if( ( $2.type & INT ) ) {
       
        if( $3.type & INT ) {

        } else {
          yyerror( "Arg 2 must be integer" );
          return 1;
        }

      } else { 
        yyerror( "Arg 1 must be integer" );
        return 1;
      }
     
      break;

    case TYPE_REL_OP:
      
      if( $2.type & INT ) {

        if( !( $3.type & INT ) ) {
          
          yyerror( "Arg 2 must be integer" );
          return 1;

        }

      } else if ( $2.type & STR ) {

        if( !( $3.type & STR )  ) {
          yyerror( "Arg 2 must be string" );
          return 1;
        }

      } else {
        
        yyerror( "Arg 1 must be integer or string" );
        return 1;
      }

    case TYPE_LOG_OP:

      if( $2.type & FUNC ) {

        yyerror( "Arg 1 cannot be function" );
        return 1;

      } else if( $3.type & FUNC ) {

        yyerror( "Arg 2 cannot be function" );
        return 1;

      }

      $$.type = ( FUNC | BOOL );
      $$.numParameters = NA;
      $$.returnType = BOOL;
      break;
    default:
      break;
  }

};

N_IF_EXPR : T_IF N_EXPR N_EXPR N_EXPR {
  printRule("IF_EXPR", "if EXPR EXPR EXPR");

  if( $2.type & FUNC ) {

    yyerror( "Arg 1 cannot be function" );
    return 1;
 
  }

  if( $3.type & FUNC ) {

    yyerror( "Arg 1 cannot be funciton" );
    return 1;
  
  } 
  
  if ( $4.type & FUNC ) {
    
    yyerror( "Arg 2 cannot be funciton" );
    return 1;

  }

  $$.type = ( $3.type | $4.type );
  $$.numParameters = NA;
  $$.returnType = $$.type;

};

N_LET_EXPR : T_LETSTAR T_LPAREN N_ID_EXPR_LIST T_RPAREN N_EXPR {
  printRule("LET_EXPR", "let* ( ID_EXPR_LIST ) EXPR");

  if( $5.type & FUNC ) {

    if( ( $5.returnType & FUNC || $5.returnType == NA ) ) {
      yyerror( "Arg 1 cannot be funciton" );
      return 1;
    } else {
      $$.type = $5.returnType;
      $$.numParameters = NA;
      $$.returnType = NA;
    }
    
  }

  $$.type = $5.type;
  $$.numParameters = NA;
  $$.returnType = NA;


  endScope();
};

N_ID_EXPR_LIST : {
  printRule("ID_EXPR_LIST", "epsilon");
} | N_ID_EXPR_LIST T_LPAREN T_IDENT N_EXPR T_RPAREN {
  string identifier;
  bool idFound;
  printRule("ID_EXPR_LIST", "ID_EXPR_LIST ( IDENT EXPR )");
  identifier = string( $3 );
  idFound = scopeStack.top().findEntry( identifier );

  printf( "___Adding %s to symbol table\n", identifier.c_str() );
  if( idFound ) {
    yyerror( "Multiply defined identifier" );
    return 1;
  } else {
    addToScope( SYMBOL_TABLE_ENTRY( identifier, $4 ) );
  }
};

N_LAMBDA_EXPR : T_LAMBDA T_LPAREN N_ID_LIST T_RPAREN N_EXPR {
  printRule("LAMBDA_EXPR", "lambda ( ID_LIST ) EXPR");

  $$.type = FUNC;
  $$.numParameters = $3.len;
  $$.returnType = $5.type;

  endScope();
};

N_ID_LIST : {
  printRule("ID_LIST", "epsilon");

  $$.len = 0;

} | N_ID_LIST T_IDENT {
  string identifier;
  bool idFound;

  $$.len = $1.len + 1;
  printRule("ID_LIST", "ID_LIST IDENT");
  identifier = string( $2 );
  idFound = scopeStack.top().findEntry(identifier);

  printf("___Adding %s to symbol table\n", identifier.c_str());
  if(idFound) {
    yyerror("Multiply defined identifier");
    return 1;
  } else {
    addToScope(SYMBOL_TABLE_ENTRY(identifier, INT ) );
  }
};

N_PRINT_EXPR : T_PRINT N_EXPR {
  printRule("PRINT_EXPR", "print EXPR");

  if( $2.type & FUNC ) {

    yyerror( "Arg 1 cannot be function" );
    return 1;

  }

  $$.type = $2.type;
  $$.numParameters = NA;
  $$.returnType = $2.type;

};

N_INPUT_EXPR : T_INPUT {
  printRule("INPUT_EXPR", "input");

  $$.type = ( INT | STR );
  $$.numParameters = NA;
  $$.returnType = NA;

};

N_EXPR_LIST : N_EXPR N_EXPR_LIST {
  printRule("EXPR_LIST", "EXPR EXPR_LIST");
  if($1.type == FUNC) {
    if($2.len > $1.numParameters) {
      yyerror("Too many parameters in function call");
      return 1;
    }
    else if($2.len < $1.numParameters) {
      yyerror("Too few parameters in function call");
      return 1;
    }
    $$.type = $1.returnType;
  } else {
    $$.len = $2.len + 1;
  }
} | N_EXPR {
  $$.len = 1;

  /*
  if($1.type == FUNC) {
    if($1.numParameters == 0) {
      $$.type |= $1.returnType;
    } else {
      cout << "Expr: " << $1.      
      cout << "Num expected params: " << $1.numParameters << endl;
      
      yyerror("Too few paramters in function call.");
      return 1;
    }
  }
  */

  // Add type?

  printRule("EXPR_LIST", "EXPR");
};

N_BIN_OP : N_ARITH_OP {
  printRule("BIN_OP", "ARITH_OP");
  $$.opType = TYPE_ARITH_OP;
} | N_LOG_OP {
  printRule("BIN_OP", "LOG_OP");
  $$.opType = TYPE_LOG_OP;
} | N_REL_OP {
  printRule("BIN_OP", "REL_OP");
  $$.opType = TYPE_REL_OP;
};

N_ARITH_OP : T_MULT {
  printRule("ARITH_OP", "*");
} | T_SUB {
  printRule("ARITH_OP", "-");
} | T_DIV {
  printRule("ARITH_OP", "/");
} | T_ADD {
  printRule("ARITH_OP", "+");
};

N_LOG_OP : T_AND {
  printRule("LOG_OP", "and");
} | T_OR {
  printRule("LOG_OP", "or");
};

N_REL_OP : T_LT {
  printRule("REL_OP", "<");
} | T_GT {
  printRule("REL_OP", ">");
} | T_LE {
  printRule("REL_OP", "<=");
} | T_GE {
  printRule("REL_OP", ">=");
} | T_EQ {
  printRule("REL_OP", "=");
} | T_NE {
  printRule("REL_OP", "/=");
};

N_UN_OP : T_NOT {
  printRule("UN_OP", "not");
};

%%

#include "lex.yy.c"
extern FILE *yyin;

void printRule( const char* lhs, const char* rhs) {
  printf("%s -> %s\n", lhs, rhs);
  return;
}

int yyerror(const char* s) {
  printf("Line %d: %s\n", lineNum, s);
  return 1;
}

void printTokenInfo(const char* tokenType, const char* lexeme) {
  printf("TOKEN: %-8s  LEXEME: %s\n", tokenType, lexeme);
}

void startScope() {
  scopeStack.push(SYMBOL_TABLE());
  printf("\n___Entering new scope...\n\n");
}

bool findEntryInAnyScope( const string ident ) {
  bool found;
  SYMBOL_TABLE st;
  if(scopeStack.empty()) {
    return false;
  }
  found = scopeStack.top().findEntry( ident );
  if(found) {
    return true;
  } else {
    st = scopeStack.top();
    scopeStack.pop();
    found = findEntryInAnyScope( ident );
    scopeStack.push( st );
    return(found);
  }
}

SYMBOL_TABLE_ENTRY * getEntryOfIdent( string ident ) {
  SYMBOL_TABLE_ENTRY * entry;
  SYMBOL_TABLE st;
  if(scopeStack.empty()) {
    return NULL;
  }
  entry = scopeStack.top().getEntry( ident );
  if( entry != NULL ) {
    return entry;
  } else {
    st = scopeStack.top();
    scopeStack.pop();
    entry = getEntryOfIdent( ident );
    scopeStack.push( st );
    return(entry);
  }

}

void addToScope( const SYMBOL_TABLE_ENTRY entry ) {
  scopeStack.top().addEntry( entry );
}

void endScope() {
  scopeStack.pop();
  printf( "\n___Exiting scope...\n\n" );
}

int main() {
  do {
    yyparse();
  } while (!feof(yyin));
  
  return 0;
}
