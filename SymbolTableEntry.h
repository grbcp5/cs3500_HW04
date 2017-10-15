#ifndef SYMBOL_TABLE_ENTRY_H
#define SYMBOL_TABLE_ENTRY_H

#include <string>
using namespace std;

#define UNDEFINED  -1

typedef struct {
  int type;
  int numParameters;
  int returnType;
} TYPE_INFO;

class SYMBOL_TABLE_ENTRY 
{
private:
  // Member variables
  string name;
  TYPE_INFO typeInfo;  

public:
  // Constructors
  SYMBOL_TABLE_ENTRY( ) { name = ""; typeInfo.type = UNDEFINED; }

  SYMBOL_TABLE_ENTRY(const string theName, const int theType) 
  {
    name = theName;
    typeInfo.type = theType;
    typeInfo.returnType = UNDEFINED;
    typeInfo.numParameters = UNDEFINED;
  }

  SYMBOL_TABLE_ENTRY( const string theName, const TYPE_INFO type ) {
    name = theName;
    typeInfo = type;
  }
  
  // Accessors
  string getName() const { return name; }
  int getTypeCode() const { return typeInfo.type; }
  TYPE_INFO getTypeInfo() const { return typeInfo;  }
};

#endif  // SYMBOL_TABLE_ENTRY_H
