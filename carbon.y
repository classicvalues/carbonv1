/*
Copyright (C) 2020 Prashant Shah <pshah.crb@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

%require  "3.0"
%skeleton "lalr1.cc"

%code requires {
	#include "ast.h"
	namespace yy {
		class Lexer;  // Generated by reflex with namespace=yy lexer=Lexer lex=yylex
	}
}

%defines
%parse-param { yy::Lexer& lexer }  // Construct parser object with lexer
%define api.value.type variant

%code {
	#include <typeinfo>
	#include "ast.h"
	#include "lex.yy.h"  // header file generated with reflex --header-file
	#undef yylex
	#define yylex lexer.yylex  // Within bison's parse() we should invoke lexer.yylex(), not the global yylex()

	//#define DEBUG(str) std::cout << str
	#define DEBUG(str) ;
	#define ERR(str) std::cout << str
	#define ALERT(str) std::cout << "\n" \
		<< "**********************************************" << "\n" \
		<< "                   " << str << "\n" \
		<< "**********************************************" << "\n";

	SourceFile sf;

	// LLVMContext owns a lot of core LLVM data structures, such as the type and constant value tables.
	llvm::LLVMContext Context;
	// IRBuilder is a helper to generate LLVM instructions
	llvm::IRBuilder<> Builder(Context);
	// Top level structure that contains functions and global variables
	std::unique_ptr<llvm::Module> Module;
	// Basic block
	llvm::BasicBlock *BB;
}

%token <int> NAMESAPCE
%token <int> IMPORT FROM AS
%token <int> STR1_LITERAL STR2_LITERAL RSTR1_LITERAL RSTR2_LITERAL
%token <int> HSTR1_LITERAL HSTR2_LITERAL HRSTR1_LITERAL HRSTR2_LITERAL
%token <int> FUNC_RETURN
%token <std::string> IDENTIFIER
%token <int> DEF
%token <int> BOOL CHAR BYTE
%token <int> INT INT8 INT16 INT32 INT64 UINT UINT8 UINT16 UINT32 UINT64
%token <int> FLOAT32 FLOAT64 FLOAT128
%token <int> STRING
%token <int> POINTER
%token <int> TYPE STRUCT UNION ENUM OPTION
%token <int> EXTEND
%token <int> TRUE FALSE
%token <int> PTR_NULL
%token <int> REGISTER STATIC
%token <int> CONST VOLATILE RESTRICT ATOMIC CONST_RESTRICT
%token <std::string> BINARY_LIT OCTAL_LIT DECIMAL_LIT HEX_LIT
%token <std::string> FLOAT_LIT CHAR_LIT

%token <int> EQUAL_TO
%token <int> PLUS MINUS MULTIPLY DIVIDE MODULUS
%token <int> RIGHT_SHIFT LEFT_SHIFT RIGHT_SHIFT_US LEFT_SHIFT_US
%token <int> IS_EQUAL IS_NOT_EQUAL IS_LESS IS_GREATER IS_LESS_OR_EQ IS_GREATER_OR_EQ
%token <int> LOGICAL_OR LOGICAL_AND
%token <int> BITWISE_AND BITWISE_OR BITWISE_NOT BITWISE_XOR
%token <int> LU_NOT LU_2COMP LU_ADD_OF RU_INC RU_DEC
%token <int> PTR_MEMBER

%token <int> RETURN BREAK CONTINUE GOTO FALLTHROUGH IF ELSE FOR WHILE DO SWITCH CASE DEFAULT DEFER

%token <int> PUBLIC PRIVATE

%left PLUS MINUS MULTIPLY DIVIDE MODULUS
%left RIGHT_SHIFT LEFT_SHIFT RIGHT_SHIFT_US LEFT_SHIFT_US
%left IS_EQUAL IS_NOT_EQUAL IS_LESS IS_GREATER IS_LESS_OR_EQ IS_GREATER_OR_EQ
%left LOGICAL_OR LOGICAL_AND
%left BITWISE_AND BITWISE_OR BITWISE_NOT BITWISE_XOR
%left U_NOT U_2COMP U_ADD_OF U_POINTER U_INC U_DEC

%nterm <int> source_file
%nterm <TopLevel *> top_level
%nterm <FunctionDefn *> func_defn
%nterm <Storage *> storage_class
%nterm <TypeQualifier *> type_qualifier
%nterm <TypeName *> type_name
%nterm <Type *> type
%nterm <Block *> block
%nterm <Statements *> statements
%nterm <Statement *> statement
%nterm <VarDeclStmt *> var_decl_stmt
%nterm <Literal *> literal
%nterm <BooleanLiteral *> bool_lit
%nterm <IntegerLiteral *> int_lit
%nterm <FloatLiteral *> float_lit
%nterm <CharLiteral *> char_lit
%nterm <StringLiteral *> str_lit
%nterm <PointerLiteral * > ptr_lit
%nterm <FunctionLiteral *> func_lit
%nterm <CompositeLiteral *> composite_lit
%nterm <CompositeTypeDefn *> composite_type_defn
%nterm <StructDefn *> struct_defn
%nterm <UnionDefn *> union_defn
%nterm <EnumDefn *> enum_defn
%nterm <OptionDefn *> option_defn
%nterm <StructUnionOptionFields *> struct_union_option_fields
%nterm <TypeIdentifier *> type_identifier
%nterm <FunctionSign *> func_sign
%nterm <FunctionParam *> func_param
%nterm <FunctionReturn *> func_return

%nterm <SelectionStmt *> selection_stmt
%nterm <IfElseStmt *> if_else_stmt
%nterm <SwitchStmt *> switch_stmt

%nterm <Expression *> expression
%nterm <UnaryExpression *> unary_expr
%nterm <BinaryExpression *> binary_expr
%nterm <Operand *> operand
%nterm <QualifiedIdent *> qualified_ident
%nterm <Index *> index
%nterm <FunctionCall *> function_call

%start source_file

%%

source_file
		: source_file top_level		{
							sf.t.push_back($2);
							DEBUG("[SourceFile]");
						}
		| top_level			{
							sf.t.push_back($1);
							DEBUG("[SourceFile]");
						}
		;

top_level
		: import_decl			{
							$$ = new TopLevel();
							$$->type = TopLevel::types::IMPORT_DECL;
							// $$->fd = $1;
							DEBUG("[TopLevel::ImportDecl]");
						}
		| composite_type_defn		{
							$$ = new TopLevel();
							$$->type = TopLevel::types::COMPOSITE_TYPE_DEFN;
							$$->ctd = $1;
							$$->ctd->is_global = true;
							DEBUG("[TopLevel::CompositeTypeDefn]");
						}
		| type_func			{
							$$ = new TopLevel();
							$$->type = TopLevel::types::TYPE_FUNC;
							// $$->fd = $1;
							DEBUG("[TopLevel::TypeFunction]");
						}
		| namespace_defn		{
							$$ = new TopLevel();
							$$->type = TopLevel::types::NAMESPACE_DEFN;
							// $$->fd = $1;
							DEBUG("[TopLevel::NamespaceDefn]");
						}
		| func_defn			{
							$$ = new TopLevel();
							$$->type = TopLevel::types::FUNC_DEFN;
							$$->fd = $1;
							DEBUG("[TopLevel::FunctionDefn]");
						}
		;

import_decl
		: IMPORT STR1_LITERAL FROM STR1_LITERAL AS STR1_LITERAL
						{
							DEBUG("[Import From As]");
						}
		| IMPORT STR1_LITERAL FROM STR1_LITERAL
						{
							DEBUG("[Import From]");
						}
		| IMPORT STR1_LITERAL		{
							DEBUG("[Import]");
						}
		;

namespace_defn
		: NAMESAPCE IDENTIFIER block 	{
							DEBUG("[NS]");
						}
		;

func_defn
		: DEF IDENTIFIER func_sign block
						{
							$$ = new FunctionDefn();
							$$->fn = $2;
							$$->fs = $3;
							$$->b = $4;
							DEBUG("[FunctionDefn]");
						}
		| access_modifier DEF IDENTIFIER func_sign block
						{
							$$ = new FunctionDefn();
							$$->fn = $3;
							$$->fs = $4;
							$$->b = $5;
							DEBUG("[FunctionDefn]");
						}
		;

access_modifier
		: PUBLIC
		| PRIVATE
		;

func_sign
		: '(' func_param ')' FUNC_RETURN '(' func_return ')'
						{
							$$ = new FunctionSign();
							$$->fp = $2;
							$$->fr = $6;
							DEBUG("[Block]");
						}
		;

block
		: '{' statements '}'		{
							$$ = new Block();
							$$->s = $2;
							DEBUG("[Block]");
						}
		| '{' '}'			{
							$$ = new Block();
							$$->s = NULL;
							DEBUG("[Block]");
						}
		;

func_param
		: /* empty */
						{
							$$ = new FunctionParam();
							$$->is_set = false;
							DEBUG("[FunctionParam]");
						}
		| func_param ',' type_identifier
						{
							$1->fpl.push_back($3);
							$$ = $1;
							DEBUG("[FunctionParam]");
						}
		| type_identifier
						{
							$$ = new FunctionParam();
							$$->is_set = true;
							$$->fpl.push_back($1);
							DEBUG("[FunctionParam]");
						}
		;

func_return
		: /* empty */
						{
							$$ = new FunctionReturn();
							$$->is_set = false;
							DEBUG("[FunctionReturn]");
						}
		| func_return ',' type_identifier
						{
							$1->frl.push_back($3);
							$$ = $1;
							DEBUG("[FunctionReturn]");
						}
		| func_return ',' type
						{
							TypeIdentifier *ti = new TypeIdentifier();
							ti->t = $3;
							ti->ident = "";

							$1->frl.push_back(ti);
							$$ = $1;
							DEBUG("[FunctionReturn]");
						}
		| type_identifier
						{
							$$ = new FunctionReturn();
							$$->is_set = true;
							$$->frl.push_back($1);
							DEBUG("[FunctionReturn]");
						}
		| type
						{
							$$ = new FunctionReturn();
							$$->is_set = true;

							TypeIdentifier *ti = new TypeIdentifier();
							ti->t = $1;
							ti->ident = "";

							$$->frl.push_back(ti);
							DEBUG("[FunctionReturn]");
						}
		;

type_func
		: EXTEND type_name '{' func_defns '}'
						{
							DEBUG("[Type Function]");
						}
		| EXTEND type_name '{' '}'	{
							DEBUG("[Type Function]");
						}
		;

func_defns
		: func_defn
		| func_defns func_defn
		;

/******************************************************************************************/
/************************************** TYPES *********************************************/
/******************************************************************************************/

type
		: storage_class type_qualifier type_name
						{
							$$ = new Type();
							$$->storage = $1;
							$$->type_qualifier = $2;
							$$->type_name = $3;
							DEBUG("[Type->S::Q::T]");
						}
		| storage_class type_name
						{
							$$ = new Type();
							$$->storage = $1;
							$$->type_qualifier = NULL;
							$$->type_name = $2;
							DEBUG("[Type->S::T]");
						}
		| type_qualifier type_name
						{
							$$ = new Type();
							$$->storage = NULL;
							$$->type_qualifier = $1;
							$$->type_name = $2;
							DEBUG("[Type->Q::T]");
						}
		| type_name
						{
							$$ = new Type();
							$$->storage = NULL;
							$$->type_qualifier = NULL;
							$$->type_name = $1;
							DEBUG("[Type->T]");
						}
		;

storage_class
		: REGISTER			{
							$$ = new Storage();
							$$->storage = Storage::storages::REGISTER;
							DEBUG("[Storage::Register]");
						}
		| STATIC			{
							$$ = new Storage();
							$$->storage = Storage::storages::STATIC;
							DEBUG("[Storage::Static]");
						}
		;

type_qualifier
		: CONST				{
							$$ = new TypeQualifier();
							$$->type_qualifier = TypeQualifier::type_qualifiers::CONST;
							DEBUG("[TypeQualifier::Const]");
						}
		| VOLATILE			{
							$$ = new TypeQualifier();
							$$->type_qualifier = TypeQualifier::type_qualifiers::VOLATILE;
							DEBUG("[TypeQualifier::Volatile]");
						}
		| RESTRICT			{
							$$ = new TypeQualifier();
							$$->type_qualifier = TypeQualifier::type_qualifiers::RESTRICT;
							DEBUG("[TypeQualifier::Restrict]");
						}
		| ATOMIC			{
							$$ = new TypeQualifier();
							$$->type_qualifier = TypeQualifier::type_qualifiers::ATOMIC;
							DEBUG("[TypeQualifier::Atomic]");
						}
		| CONST_RESTRICT		{
							$$ = new TypeQualifier();
							$$->type_qualifier = TypeQualifier::type_qualifiers::CONST_RESTRICT;
							DEBUG("[TypeQualifier::ConstRestrict]");
						}
		;

type_name
		: BOOL				{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::BOOL;
							DEBUG("[Type::Bool]");
						}
		| CHAR				{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::CHAR;
							DEBUG("[Type::Char]");
						}
		| BYTE				{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::BYTE;
							DEBUG("[Type::Byte]");
						}
		| INT				{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::INT;
							DEBUG("[Type::Int]");
						}
		| INT8				{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::INT8;
							DEBUG("[Type::Int8]");
						}
		| INT16				{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::INT16;
							DEBUG("[Type::Int16]");
						}
		| INT32				{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::INT32;
							DEBUG("[Type::Int32]");
						}
		| INT64				{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::INT64;
							DEBUG("[Type::Int64]");
						}
		| UINT				{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::UINT;
							DEBUG("[Type::UInt]");
						}
		| UINT8				{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::UINT8;
							DEBUG("[Type::UInt8]");
						}
		| UINT16			{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::UINT16;
							DEBUG("[Type::UInt16]");
						}
		| UINT32			{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::UINT32;
							DEBUG("[Type::UInt32]");
						}
		| UINT64			{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::UINT64;
							DEBUG("[Type::UInt64]");
						}
		| FLOAT32			{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::FLOAT32;
							DEBUG("[Type::Float32]");
						}
		| FLOAT64			{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::FLOAT64;
							DEBUG("[Type::Float64]");
						}
		| FLOAT128			{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::FLOAT128;
							DEBUG("[Type::Float128]");
						}
		| STRING			{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::STRING;
							DEBUG("[Type::String]");
						}
		| POINTER ':' type_name		{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::POINTER;
							DEBUG("[Type::Pointer]");
						}
/*		| tupple_type			{
							DEBUG("[Tupple]");
							}
*/
/*		| function_type			{
							DEBUG("[Function]");
						}
*/
		| IDENTIFIER			{
							$$ = new TypeName();
							$$->type_name = TypeName::type_names::CUSTOM;
							DEBUG("[Type::CustomType]");
						}
		;

/*
function_type
		: '(' func_param_type ')' FUNC_RETURN '(' func_ret_type ')'
		;

func_param_type
		: type
		| func_param_type ',' type
		;

func_ret_type
		: type
		| func_ret_type ',' type
		;
*/

/******************************************************************************************/
/************************************** STATEMENTS ****************************************/
/******************************************************************************************/

statements
		: statements statement		{
							$1->s.push_back($2);
							$$ = $1;
							DEBUG("[Statements]");
						}
		| statement			{
							$$ = new Statements();
							$$->is_set = true;
							$$->s.push_back($1);
							DEBUG("[Statements]");
						}
		;

statement
		: var_decl_stmt			{
							$$ = new Statement();
							$$->type = Statement::types::VAR_DECL;
							$$->vds = $1;
							DEBUG("[Stmt:VarDeclStmt]");
						}
		| composite_type_defn		{
							$$ = new Statement();
							$$->type = Statement::types::COMPOSITE_TYPE_DEFN;
							$$->ctds = $1;
							$$->ctds->is_global = false;
							DEBUG("[Stmt:CompositeTypeDefnStmt]");
						}
		| expression_stmt		{
							$$ = new Statement();
							$$->type = Statement::types::EXPRESSION;
							// $$->es = &$1;
							DEBUG("[Stmt:ExprStmt]");
						}
		| assignment_stmt		{
							$$ = new Statement();
							$$->type = Statement::types::ASSIGNMENT;
							// $$->as = &$1;
							DEBUG("[Stmt:AssignStmt]");
						}
/*	| inc_dec_stmt				*/
		| selection_stmt		{
							$$ = new Statement();
							$$->type = Statement::types::SELECTION;
							$$->ss = $1;
							DEBUG("[Stmt:SelectionStmt]");
						}
		| iteration			{
							$$ = new Statement();
							$$->type = Statement::types::ITERATION;
							// $$->is = &$1;
							DEBUG("[Stmt:IterationStmt]");
						}
		| jump_stmt			{
							$$ = new Statement();
							$$->type = Statement::types::JUMP;
							// $$->js = &$1;
							DEBUG("[Stmt:JumpStmt]");
						}
		| defer_stmt			{
							$$ = new Statement();
							$$->type = Statement::types::DEFER;
							// $$->ds = &$1;
							DEBUG("[Stmt:DeferStmt]");
						}

/******************************************************************************************/
/************************************** LITERAL *******************************************/
/******************************************************************************************/

literal
		: bool_lit			{
							$$ = new Literal();
							$$->type = Literal::types::BOOL;
							$$->boolean = $1;
							DEBUG("[Literal::Boolean]");
						}
		| int_lit			{
							$$ = new Literal();
							$$->type = Literal::types::INT;
							$$->integer = $1;
							DEBUG("[Literal::Integer]");
						}
		| float_lit			{
							$$ = new Literal();
							$$->type = Literal::types::FLOAT;
							$$->floating = $1;
							DEBUG("[Literal::Float]");
						}
		| char_lit			{
							$$ = new Literal();
							$$->type = Literal::types::CHAR;
							$$->character = $1;
							DEBUG("[Literal::Char]");
						}
		| str_lit			{
							$$ = new Literal();
							$$->type = Literal::types::STRING;
							$$->string = $1;
							DEBUG("[Literal::String]");
						}
		| ptr_lit			{
							$$ = new Literal();
							$$->type = Literal::types::POINTER;
							$$->pointer = $1;
							DEBUG("[Literal::Pointer]");
						}
		| func_lit			{
							$$ = new Literal();
							$$->type = Literal::types::FUNCTION;
							$$->function = $1;
							DEBUG("[Literal::Function]");
						}
		| composite_lit			{
							$$ = new Literal();
							$$->type = Literal::types::COMPOSITE;
							$$->composite = $1;
							DEBUG("[Literal::Composite]");
						}
		/* TODO: | tupple_lit */
		;

bool_lit
		: TRUE				{
							$$ = new BooleanLiteral();
							$$->type = BooleanLiteral::types::TRUE;
							DEBUG("[Literal::Boolean::True]");
						}
		| FALSE				{
							$$ = new BooleanLiteral();
							$$->type = BooleanLiteral::types::FALSE;
							DEBUG("[Literal::Boolean::False]");
						}
		;

int_lit
		: BINARY_LIT			{
							$$ = new IntegerLiteral();
							$$->type = IntegerLiteral::types::BINARY;

							std::string bin_str = $1;
							bin_str.erase(0, 2);

							int len = bin_str.length();
							if (len <= 8) {
								$$->reg_size = 8;
							} else if (len <= 16) {
								$$->reg_size = 16;
							} else if (len <= 32) {
								$$->reg_size = 32;
							} else if (len <= 64) {
								$$->reg_size = 64;
							} else {
								ERR("Size of binary number is too large");
							}

							$$->value = stol(bin_str, nullptr, 2);

							DEBUG("[Literal::Integer::Binary]");
						}
		| OCTAL_LIT			{
							$$ = new IntegerLiteral();
							$$->type = IntegerLiteral::types::OCTAL;

							std::string oct_str = $1;
							oct_str.erase(0, 2);

							$$->reg_size = 64;

							$$->value = stol(oct_str, nullptr, 8);

							DEBUG("[Literal::Integer::Octal]");
						}
		| DECIMAL_LIT			{
							$$ = new IntegerLiteral();
							$$->type = IntegerLiteral::types::DECIMAL;

							std::string dec_str = $1;

							$$->reg_size = 64;

							$$->value = stol(dec_str, nullptr, 10);

							DEBUG("[Literal::Integer::Decimal]");
						}
		| HEX_LIT			{
							$$ = new IntegerLiteral();
							$$->type = IntegerLiteral::types::HEX;

							std::string hex_str = $1;
							hex_str.erase(0, 3);

							int len = hex_str.length();
							if (len <= 2) {
								$$->reg_size = 8;
							} else if (len <= 4) {
								$$->reg_size = 16;
							} else if (len <= 8) {
								$$->reg_size = 32;
							} else if (len <= 16) {
								$$->reg_size = 64;
							} else {
								ERR("Size of hex number is too large");
							}

							$$->value = stol(hex_str, nullptr, 16);

							DEBUG("[Literal::Integer::Hex]");
						}
		;

float_lit
		: FLOAT_LIT			{
							$$ = new FloatLiteral();
							DEBUG("[Literal::Float]");
						}
		;

char_lit
		: CHAR_LIT			{
							$$ = new CharLiteral();
							DEBUG("[Literal::Char]");
						}
		;

str_lit
		: STR1_LITERAL			{
							$$ = new StringLiteral();
							$$->type = StringLiteral::types::STR1;
							DEBUG("[Literal::String::Str1]");
						}
		| STR2_LITERAL			{
							$$ = new StringLiteral();
							$$->type = StringLiteral::types::STR2;
							DEBUG("[Literal::String::Str2]");
						}
		| RSTR1_LITERAL			{
							$$ = new StringLiteral();
							$$->type = StringLiteral::types::RSTR1;
							DEBUG("[Literal::String::RStr1]");
						}
		| RSTR2_LITERAL			{
							$$ = new StringLiteral();
							$$->type = StringLiteral::types::RSTR2;
							DEBUG("[Literal::String::RStr2]");
						}
		| HSTR1_LITERAL			{
							$$ = new StringLiteral();
							$$->type = StringLiteral::types::HSTR1;
							DEBUG("[Literal::String::HStr1]");
						}
		| HSTR2_LITERAL			{
							$$ = new StringLiteral();
							$$->type = StringLiteral::types::HSTR2;
							DEBUG("[Literal::String::HStr2]");
						}
		| HRSTR1_LITERAL		{
							$$ = new StringLiteral();
							$$->type = StringLiteral::types::HRSTR1;
							DEBUG("[Literal::String::HRStr1]");
						}
		| HRSTR2_LITERAL		{
							$$ = new StringLiteral();
							$$->type = StringLiteral::types::HRSTR2;
							DEBUG("[Literal::String::HRStr2]");
						}
		;

ptr_lit
		: PTR_NULL			{
							$$ = new PointerLiteral();
							DEBUG("[Literal::Pointer]");
						}
		;

func_lit
		: DEF func_sign block		{
							$$ = new FunctionLiteral();
							DEBUG("[Literal::Function]");
						}
		;

composite_lit
		: IDENTIFIER '{' composite_list '}'
						{
							$$ = new CompositeLiteral();
							DEBUG("[Literal::Composite]");
						}
		;

composite_list
		: keyed_element
		| composite_list ',' keyed_element
		;

keyed_element
		: comp_element
		| comp_key ':' comp_element
		;

comp_key
		: IDENTIFIER
		;

comp_element
		: literal
		;

/*
tupple_lit
		: '(' tupple_items ')'
		;

tupple_items
		: tupple_item
		| tupple_items ',' tupple_item
		;

tupple_item
		: IDENTIFIER
		| literal
		| expression
		;
*/

/******************************************************************************************/
/******************************* COMPOSITE TYPE DEFINITION ********************************/
/******************************************************************************************/

composite_type_defn
		: struct_defn			{
							$$ = new CompositeTypeDefn();
							$$->type = CompositeTypeDefn::types::STRUCT;
							$$->s = $1;
							DEBUG("[CompositeTypeDefn::Struct]");
						}
		| union_defn			{
							$$ = new CompositeTypeDefn();
							$$->type = CompositeTypeDefn::types::UNION;
							$$->u = $1;
							DEBUG("[CompositeTypeDefn::Union]");
						}
		| enum_defn			{
							$$ = new CompositeTypeDefn();
							$$->type = CompositeTypeDefn::types::ENUM;
							$$->e = $1;
							DEBUG("[CompositeTypeDefn::Enum]");
						}
		| option_defn			{
							$$ = new CompositeTypeDefn();
							$$->type = CompositeTypeDefn::types::OPTION;
							$$->o = $1;
							DEBUG("[CompositeTypeDefn::Option]");
						}
		;

struct_defn
		: STRUCT IDENTIFIER '{' struct_union_option_fields '}'
						{
							$$ = new StructDefn();
							$$->ident = $2;
							$$->f = $4;
							DEBUG("[Struct Defn]");
						}
		| STRUCT IDENTIFIER '{' '}'
						{
							$$ = new StructDefn();
							$$->ident = $2;
							DEBUG("[Struct Defn]");
						}
		;

union_defn
		: UNION IDENTIFIER '{' struct_union_option_fields '}'
						{
							$$ = new UnionDefn();
							$$->ident = $2;
							$$->f = $4;
							DEBUG("[Union Defn]");
						}
		| UNION IDENTIFIER '{' '}'
						{
							$$ = new UnionDefn();
							$$->ident = $2;
							DEBUG("[Union Defn]");
						}
		;

enum_defn
		: ENUM IDENTIFIER '{' enum_fields '}'
						{
							$$ = new EnumDefn();
							DEBUG("[Enum Defn]");
						}
		;

option_defn
		: OPTION IDENTIFIER '{' struct_union_option_fields '}'
						{
							$$ = new OptionDefn();
							DEBUG("[Option Defn]");
						}
		;

struct_union_option_fields
		: struct_union_option_fields type_identifier
						{
							$1->ti.push_back($2);
							$$ = $1;
							DEBUG("[StructUnionOptionFields]");
						}
		| type_identifier		{
							$$ = new StructUnionOptionFields();
							$$->is_set = true;
							$$->ti.push_back($1);
							DEBUG("[StructUnionOptionFields::TypeIdentifier]");
						}
		;

type_identifier : type IDENTIFIER		{
							$$ = new TypeIdentifier();
							$$->t = $1;
							$$->ident = $2;
							DEBUG("[TypeIdentifier]");
						}
		;

enum_fields
		: IDENTIFIER
		| enum_fields IDENTIFIER
		;

/******************************************************************************************/
/************************************** OPERATORS *****************************************/
/******************************************************************************************/

arith_op
		: PLUS				{
							DEBUG("[+]");
						}
		| MINUS				{
							DEBUG("[-]");
						}
		| MULTIPLY			{
							DEBUG("[-]");
						}
		| DIVIDE			{
							DEBUG("[/]");
						}
		| MODULUS			{
							DEBUG("[%%]");
						}
		;

shift_op
		: RIGHT_SHIFT			{
							DEBUG("[<<]");
						}
		| LEFT_SHIFT			{
							DEBUG("[>>]");
						}
		| RIGHT_SHIFT_US		{
							DEBUG("[<<<]");
						}
		| LEFT_SHIFT_US			{
							DEBUG("[>>>]");
						}
		;

logical_op
		: LOGICAL_AND			{
							DEBUG("[&&]");
						}
		| LOGICAL_OR			{
							DEBUG("[||]");
						}
		;

assign_op
		: EQUAL_TO			{
							DEBUG("[=]");
						}
		| arith_op EQUAL_TO		{
							DEBUG("[Arith =]");
						}
		| shift_op EQUAL_TO		{
							DEBUG("[Shift =]");
						}
		| logical_op EQUAL_TO		{
							DEBUG("[Logical =]");
						}
		;

/******************************************************************************************/
/******************************* ASSIGNMENT STATEMENT *************************************/
/******************************************************************************************/

assignment_stmt
		: l_value_list assign_op expression
						{
							DEBUG("[Assign stmt]");
						}
		;

l_value_list
		: l_value
		| l_value_list ',' l_value
		;

l_value
		: qualified_ident
		| U_ADD_OF unary_expr		{
							DEBUG("[@]");
						}
		| U_POINTER unary_expr		{
							DEBUG("[$]");
						}
		| operand index			{
							DEBUG("[LHS Array Index]");
						}
		;

expression
		: unary_expr			{
							$$ = new Expression();
							$$->type = Expression::types::UNARY;
							$$->ue = $1;
							DEBUG("[UnaryExpr]");
						}
		| binary_expr			{
							$$ = new Expression();
							$$->type = Expression::types::BINARY;
							$$->be = $1;
							DEBUG("[BinaryExpr]");
						}
		;

binary_expr
		: expression PLUS expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::PLUS;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::+");
						}
		| expression MINUS expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::MINUS;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::-");
						}
		| expression MULTIPLY expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::MULTIPLY;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::*");
						}
		| expression DIVIDE expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::DIVIDE;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::/");
						}
		| expression MODULUS expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::MODULUS;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::%%");
						}
		| expression RIGHT_SHIFT expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::RIGHT_SHIFT;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::>>");
						}
		| expression LEFT_SHIFT expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::LEFT_SHIFT;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::<<");
						}
		| expression RIGHT_SHIFT_US expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::RIGHT_SHIFT_US;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::>>>");
						}
		| expression LEFT_SHIFT_US expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::LEFT_SHIFT_US;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::<<<");
						}
		| expression LOGICAL_AND expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::LOGICAL_AND;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::&");
						}
		| expression LOGICAL_OR expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::LOGICAL_OR;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::|");
						}
		| expression IS_EQUAL expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::IS_EQUAL;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::==");
						}
		| expression IS_NOT_EQUAL expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::IS_NOT_EQUAL;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::!=");
						}
		| expression IS_LESS expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::IS_LESS;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::<");
						}
		| expression IS_GREATER expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::IS_GREATER;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::>");
						}
		| expression IS_LESS_OR_EQ expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::IS_LESS_OR_EQ;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::<=");
						}
		| expression IS_GREATER_OR_EQ expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::IS_GREATER_OR_EQ;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::>=");
						}
		| expression BITWISE_AND expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::BITWISE_AND;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::&&");
						}
		| expression BITWISE_OR expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::BITWISE_OR;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::||");
						}
		| expression BITWISE_NOT expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::BITWISE_NOT;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::^");
						}
		| expression BITWISE_XOR expression
						{
							$$ = new BinaryExpression();
							$$->type = BinaryExpression::types::BITWISE_XOR;
							$$->le = $1;
							$$->re = $3;
							DEBUG("BinaryExpr::&^");
						}
		;

unary_expr
		: U_NOT unary_expr		{
							$$ = new UnaryExpression();
							$$->type = UnaryExpression::types::U_NOT;
							$$->ue = $2;
							DEBUG("UnaryExpr::!");
						}
		| U_2COMP unary_expr		{
							$$ = new UnaryExpression();
							$$->type = UnaryExpression::types::U_2COMP;
							$$->ue = $2;
							DEBUG("UnaryExpr::~");
						}
		| U_ADD_OF unary_expr		{
							$$ = new UnaryExpression();
							$$->type = UnaryExpression::types::U_ADD_OF;
							$$->ue = $2;
							DEBUG("UnaryExpr::@");
						}
		| MULTIPLY unary_expr		{
							$$ = new UnaryExpression();
							$$->type = UnaryExpression::types::MULTIPLY;
							$$->ue = $2;
							DEBUG("UnaryExpr::$");
						}
		| PLUS unary_expr		{
							$$ = new UnaryExpression();
							$$->type = UnaryExpression::types::PLUS;
							$$->ue = $2;
							DEBUG("UnaryExpr::+a");
						}
		| MINUS unary_expr		{
							$$ = new UnaryExpression();
							$$->type = UnaryExpression::types::MINUS;
							$$->ue = $2;
							DEBUG("UnaryExpr::-a");
						}
		| '(' expression ')'		{
							$$ = new UnaryExpression();
							$$->type = UnaryExpression::types::BRACES;
							$$->e = $2;
							DEBUG("UnaryExpr::()");
						}
		| operand			{
							$$ = new UnaryExpression();
							$$->type = UnaryExpression::types::OPERAND;
							$$->o = $1;
							DEBUG("UnaryExpr::Operand");
						}
		;

operand
		: literal			{
							$$ = new Operand();
							$$->type = Operand::types::LITERAL;
							$$->l = $1;
							DEBUG("Operand::Literal");
						}
		| qualified_ident		{
							$$ = new Operand();
							$$->type = Operand::types::QUALIFIED_IDENT;
							$$->qi = $1;
							DEBUG("Operand::Literal");
						}
		| operand index			{
							$$ = new Operand();
							$$->type = Operand::types::INDEX;
							$$->i = $2;
							DEBUG("Operand::ArrayIndex");
						}
		| operand function_call		{
							$$ = new Operand();
							$$->type = Operand::types::FUNCTION_CALL;
							$$->fc = $2;
							DEBUG("Operand::FunctionCall");
						}
		;

qualified_ident
		: IDENTIFIER
						{
							$$ = new QualifiedIdent;
							DEBUG("[Identifier]");
						}
		| qualified_ident '.' IDENTIFIER
						{
							$$ = new QualifiedIdent;
							DEBUG("[Identifier::X.Y");
						}
		| qualified_ident PTR_MEMBER IDENTIFIER
						{
							$$ = new QualifiedIdent;
							DEBUG("[Identifier::X~>Y");
						}
		;

index
		: '[' expression ']'		{
							$$ = new Index;
							DEBUG("[Index");
						}
		;

function_call
		: '(' ')'			{
							$$ = new FunctionCall;
							DEBUG("[Identifier]");
						}
		| '(' expression_list ')'	{
							$$ = new FunctionCall;
							DEBUG("[Identifier]");
						}
		;

expression_list
		: expression
		| expression_list ',' expression
		;

/******************************************************************************************/
/************************************** STATEMENTS ****************************************/
/******************************************************************************************/

var_decl_stmt
		: type IDENTIFIER
						{
							$$ = new VarDeclStmt();
							$$->type = $1;
							$$->ident = $2;
							$$->lit = NULL;
							DEBUG("[VarDeclStmt::Identifier]");
						}
		| type IDENTIFIER EQUAL_TO literal
						{
							$$ = new VarDeclStmt();
							$$->type = $1;
							$$->ident = $2;
							$$->lit = $4;
							DEBUG("[VarDeclStmt::Literal::Identifier]");
						}
		;

expression_stmt
		: operand function_call		{
							DEBUG("[Function Call]");
						}
		;

iteration
		: for_stmt			{
							DEBUG("[For Stmt]");
						}
		| while_stmt			{
							DEBUG("[While Stmt]");
						}
		| dowhile_stmt			{
							DEBUG("[DoWhile Stmt]");
						}
		;

for_stmt
		: FOR '(' for_init for_cond for_post ')' block
		;

for_init
		: ';'
		| simple_stmt ';'
		;

for_cond
		: ';'
		| expression ';'
		;

for_post
		: /* empty */
		| simple_stmt
		;

simple_stmt
		: assignment_stmt
		;

while_stmt
		: WHILE '(' expression ')' block
		;

dowhile_stmt
		: DO block WHILE '(' expression ')'
		;

defer_stmt
		: DEFER block
		;

selection_stmt
		: if_else_stmt			{
							$$ = new SelectionStmt();
							$$->type = SelectionStmt::types::IF_ELSE;
							DEBUG("[SelectionStmt::IfElseStmt]");
						}
		| switch_stmt			{
							$$ = new SelectionStmt();
							$$->type = SelectionStmt::types::SWITCH;
							DEBUG("[SelectionStmt::SwitchStmt]");
						}
		;

if_else_stmt
		: if_block
						{
							$$ = new IfElseStmt();
							DEBUG("[IfElseStmt::If]");
						}
		| if_block else_block
						{
							$$ = new IfElseStmt();
							DEBUG("[IfElseStmt::IfElse]");
						}
		| if_block else_if_block else_block
						{
							$$ = new IfElseStmt();
							DEBUG("[IfElseStmt::IfElseIfElse]");
						}
		;

if_block
		: IF '(' expression ')' block
		;

else_block
		: ELSE block
		;

else_if_block
		: ELSE IF '(' expression ')' block
		| else_if_block ELSE IF '(' expression ')' block
		;

switch_stmt
		: SWITCH '(' expression ')' '{' case_block '}'
						{
							$$ = new SwitchStmt();
							DEBUG("[SwitchStmt::SwitchCase]");
						}
		| SWITCH '(' expression ')' '{' case_block case_default '}'
						{
							$$ = new SwitchStmt();
							DEBUG("[SwitchStmt::SwitchCaseDefault]");
						}
		;

case_block
		: CASE case_cond ':' statements
		| case_block CASE case_cond ':' statements
		;

case_default
		: DEFAULT ':' statements
		;

case_cond
		: expression
		;

jump_stmt
		: GOTO IDENTIFIER		{
							DEBUG("[Goto]");
						}
		| CONTINUE			{
							DEBUG("[Continue]");
						}
		| BREAK				{
							DEBUG("[Break]");
						}
		| RETURN			{
							DEBUG("[Return]");
						}
/*		| RETURN expression_list	{
							DEBUG("[Return Expr]");
						} */
		;

%%

int main() {
	// std::map<std::string, llvm::Value *> NamedValues; // Contains values defined in current scope

	// Make the module, which holds all the code.
	Module = std::make_unique<llvm::Module>("carbon module", Context);

	yy::Lexer lexer(std::cin);
	yy::parser parser(lexer);
	parser.parse();

	sf.codeGen();

	Module->print(llvm::errs(), nullptr);
	return 0;
}

void yy::parser::error(const std::string& msg) {
	std::cerr << msg << std::endl;
}
