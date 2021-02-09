#ifndef AST_H
#define AST_H

#include "llvm/ADT/APFloat.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Verifier.h"

extern llvm::LLVMContext Context;
extern llvm::IRBuilder<> Builder;
extern std::unique_ptr<llvm::Module> Module;
extern llvm::BasicBlock *BB;

class TopLevel;

class FunctionDefn;
class CompositeTypeDefn;
class Block;

class Type;
class Storage;
class TypeQualifier;
class TypeName;
class Literal;
class BooleanLiteral;
class IntegerLiteral;
class FloatLiteral;
class CharLiteral;
class StringLiteral;
class PointerLiteral;
class FunctionLiteral;
class CompositeLiteral;

class Statements;
class Statement;
class VarDeclStmt;
class ExpressionStmt;
class AssignmentStmt;
class SelectionStmt;
class IterationStmt;
class JumpStmt;
class DeferStmt;
class IfElseStmt;
class SwitchStmt;


class FunctionSign;
class FunctionParam;
class FunctionReturn;

class StructDefn;
class UnionDefn;
class EnumDefn;
class OptionDefn;
class StructUnionOptionFields;

class UnaryExpression;
class BinaryExpression;

class TypeIdentifier;

class SourceFile {
	public:
		std::list<TopLevel *> t;
		void codeGen();
};

class TopLevel {
	public:
		enum types { IMPORT_DECL, COMPOSITE_TYPE_DEFN, TYPE_FUNC, NAMESPACE_DEFN, FUNC_DEFN } type;
		FunctionDefn *fd;
		CompositeTypeDefn *ctd;
		void codeGen();
};

class ImportDecl {

};

class CompositeTypeDefn {
	public:
		enum types { STRUCT, UNION, ENUM, OPTION } type;
		bool is_global = false;
		StructDefn *s;
		UnionDefn *u;
		EnumDefn *e;
		OptionDefn *o;
		void codeGen();
};

class StructDefn {
	public:
		std::string ident;
		StructUnionOptionFields *f;
		void codeGen(bool);
};

class UnionDefn {
	public:
		std::string ident;
		StructUnionOptionFields *f;
		void codeGen(bool);
};

class EnumDefn {
	public:
		std::string ident;
		void codeGen(bool);
};

class OptionDefn {
	public:
		std::string ident;
		StructUnionOptionFields *f;
		void codeGen(bool);
};

class StructUnionOptionFields {
	public:
		bool is_set = false;
		std::list<TypeIdentifier *> ti;
		void codeGen();
};

class NamespaceDefn {

};

class FunctionDefn {
	public:
		Block *b;
		std::string fn;
		FunctionSign *fs;
		void codeGen();
};

class FunctionSign {
	public:
		FunctionParam *fp;
		FunctionReturn *fr;
};

class FunctionParam {
	public:
		bool is_set = false;
		std::list<TypeIdentifier *> fpl;
};

class FunctionReturn {
	public:
		bool is_set = false;
		std::list<TypeIdentifier *> frl;
};

class TypeFunction {

};

class Storage {
	public:
		enum storages { REGISTER, STATIC } storage;
};

class TypeQualifier {
	public:
		enum type_qualifiers { CONST, VOLATILE, RESTRICT, ATOMIC, CONST_RESTRICT} type_qualifier;
};

class TypeName {
	public:
		enum type_names { BOOL, CHAR, BYTE, INT, INT8, INT16, INT32, INT64, UINT, UINT8,
			UINT16, UINT32, UINT64, FLOAT32, FLOAT64, FLOAT128, STRING, POINTER, CUSTOM } type_name;
};

class Type {
	public:
		Storage *storage;
		TypeQualifier *type_qualifier;
		TypeName *type_name;
};

class AccessModifier {

};

class Block {
	public:
		Statements *s = NULL;
		void codeGen();
};

class Statements {
	public:
		bool is_set = false;
		std::list<Statement *> s;
		void codeGen();
};

class Statement {
	public:
		enum types { VAR_DECL, COMPOSITE_TYPE_DEFN, EXPRESSION, ASSIGNMENT, INC_DEC, SELECTION,
			ITERATION, JUMP, DEFER } type;
		VarDeclStmt *vds;
		CompositeTypeDefn *ctds;
		ExpressionStmt *es;
		AssignmentStmt *as;
		SelectionStmt *ss;
		IterationStmt *is;
		JumpStmt *js;
		DeferStmt *ds;
		void codeGen();
};

class VarDeclStmt {
	public:
		std::string ident;
		Type *type;
		Literal *lit;
		void codeGen();
};

class ExpressionStmt {

};

class AssignmentStmt {

};

class LValueList {

};

class Expression {
	public:
		enum types { UNARY, BINARY } type;
		UnaryExpression *ue;
		BinaryExpression *be;
		void codeGen();
};

class UnaryExpression {
	public:
		enum types { U_NOT, U_2COMP, U_ADD_OF, MULTIPLY, PLUS, MINUS, BRACES, OPERAND } type;
		UnaryExpression *ue;
		Expression *e;
		void codeGen();
};

class BinaryExpression {
	public:
		enum types { PLUS, MINUS, MULTIPLY, DIVIDE, MODULUS, RIGHT_SHIFT, LEFT_SHIFT,
			RIGHT_SHIFT_US, LEFT_SHIFT_US, LOGICAL_AND, LOGICAL_OR, IS_EQUAL, IS_NOT_EQUAL,
			IS_LESS, IS_GREATER, IS_LESS_OR_EQ, IS_GREATER_OR_EQ,
			BITWISE_AND, BITWISE_OR, BITWISE_NOT, BITWISE_XOR } type;
		Expression *le;
		Expression *re;
		void codeGen();
};

class ArithOp {

};

class ShiftOp {

};

class LogicalOp {

};

class AssignOp {

};

class Operand {

};

class QualifiedIdent {

};

class ExpressionList {

};

class SelectionStmt {
	public:
		enum types { IF_ELSE, SWITCH } type;
		IfElseStmt *ies;
		SwitchStmt *ss;
		void codeGen();
};

class IfElseStmt {

};

class SwitchStmt {

};

class CaseStmt {

};

class IterationStmt {

};

class ForStmt {

};

class WhileStmt {

};

class DoWhileStmt {

};

class JumpStmt {

};

class GotoStmt {

};

class ContinueStmt {

};

class BreakStmt {

};

class ReturnStmt {

};

class DeferStmt {

};

class Literal {
	public:
		enum types { BOOL, INT, FLOAT, CHAR, STRING, POINTER, FUNCTION, COMPOSITE } type;
		BooleanLiteral *boolean;
		IntegerLiteral *integer;
		FloatLiteral *floating;
		CharLiteral *character;
		StringLiteral *string;
		PointerLiteral *pointer;
		FunctionLiteral *function;
		CompositeLiteral *composite;
};

class BooleanLiteral {
	public:
		enum types { TRUE, FALSE } type;
};

class IntegerLiteral {
	public:
		enum types { BINARY, OCTAL, DECIMAL, HEX } type;
		long value = 0;
		int reg_size = 0;
};

class FloatLiteral {
	public:
		double value;
		int reg_size = 0;
};

class CharLiteral {
	public:
		char char_literal;
};

class StringLiteral {
	public:
		enum types { STR1, STR2, RSTR1, RSTR2, HSTR1, HSTR2, HRSTR1, HRSTR2 } type;
		std::string string_literal;
};

class PointerLiteral {
	public:
};

class FunctionLiteral {
	public:
};

class CompositeLiteral {
	public:
};

class TypeIdentifier {
	public:
		Type *t;
		std::string ident;
		llvm::Type *codeGen();
};

#endif /* AST_H */
