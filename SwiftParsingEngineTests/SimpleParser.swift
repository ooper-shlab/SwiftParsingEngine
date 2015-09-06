//
//  SimpleParser.swift
//  SwiftParsingEngine
//
//  Created by 開発 on 2015/9/3.
//  Copyright © 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation
import SwiftParsingEngine

/* ---------------------------------------------------------------------------------------- *
    [Parser]

    In the parser category, you declare three kinds of types,
    and two types of Pattern type instances.

    Type 1. ParsingState type
    Type 2. Pattern classes
    Instances 1. NonTerminal patterns
    Instances 2. Terminal patters
    Type 3. Parser class

* ---------------------------------------------------------------------------------------- */

struct SimpleState: ParsingStateType {
    var context: SimpleContext
    var currentPosition: Int
    init() {
        context = SimpleContext.Initial
        currentPosition = 0
    }
}

class SimpleNonTerminal: NonTerminalBase<SimpleContext, SimpleState> {
    override init(nodeConstructor: NodeConstructorType) {
        super.init(nodeConstructor :nodeConstructor)
    }
}

//MARK: Non terminal symbols
let SimpleScript = SimpleNonTerminal{match in
    let node = SimpleScriptNode()
    node.childNodes = match.nodes.filter{$0 is SimpleNode}
    return node
}
let SimpleStatement = SimpleNonTerminal{_ in SimpleStatementNode()}
let SimpleExpression = SimpleNonTerminal{_ in SimpleExpressionNode()}
let SimpleDeclaration = SimpleNonTerminal{_ in SimpleDeclarationNode()}
let SimpleIfStatement = SimpleNonTerminal{_ in SimpleIfNode()}
let SimpleWhileStatement = SimpleNonTerminal{_ in SimpleWhileNode()}

let SimpleAssignment = SimpleNonTerminal{_ in SimpleBinaryNode()}
let SimpleDisjunction = SimpleNonTerminal{_ in SimpleBinaryNode()}
let SimpleConjunction = SimpleNonTerminal{_ in SimpleBinaryNode()}
let SimpleNegation = SimpleNonTerminal{_ in SimpleUnaryNode()}
let SimpleComparative = SimpleNonTerminal{_ in SimpleBinaryNode()}
let SimpleAddition = SimpleNonTerminal{_ in SimpleBinaryNode()}
let SimpleTerm = SimpleNonTerminal{_ in SimpleBinaryNode()}
let SimplePrefix = SimpleNonTerminal{_ in SimpleUnaryNode()}
let SimpleFuncall = SimpleNonTerminal{_ in SimpleBinaryNode()}
let SimpleParameter = SimpleNonTerminal{_ in SimpleParameterNode()}

let SimpleFactor = SimpleNonTerminal{_ in SimpleFactorNode()}
let SimpleConstant = SimpleNonTerminal{_ in SimpleConstantNode()}

let SimpleBlock = SimpleNonTerminal{_ in SimpleBlockNode()}

//MARK: Terminal symbols
let SimpleVariable = Terminal(SimpleIdentifierToken)
let SimpleStringConstant = Terminal(SimpleStringLiteralToken)
let SimpleNumericConstant = Terminal(SimpleNumericLiteralToken)
let SimpleEnd = Terminal(EndToken)
let SN = Terminal(SimpleNewlineToken)
let SimpleAssignmentOperator = AnySymbol("=", "+=", "-=", "*=", "/=", "^=", "&=", "|=", "<<=", ">>=", ">>>=", "??=")
let SimpleDisjunctionOperator = AnySymbol("||", "??")
let SimpleConjunctionOperator = AnySymbol("&&")
let SimpleComparativeOperator = AnySymbol("<", "<=", ">", ">=", "==", "!=", "===", "!==")
let SimpleAdditionalOperator = AnySymbol("+", "-", "|", "^")
let SimpleMultiplicationOperator = AnySymbol("*", "/", "&", "<<", ">>", ">>>")
let SimplePrefixOperator = AnySymbol("+", "-", "!", "~")

class SimpleParser: ParserBase<SimpleContext, SimpleState> {
    var _state: SimpleState = SimpleState()
    override var state: SimpleState {
        get {
            _state.context = tokenizer.currentContext
            _state.currentPosition = tokenizer.currentPosition
            return _state
        }
        set {
            _state = newValue
            tokenizer.currentContext = _state.context
            tokenizer.currentPosition = _state.currentPosition
        }
    }
    override func setup() {
        SimpleScript ==> (SN* & (SimpleStatement | SimpleDeclaration))* & SN* & SimpleEnd
        
        SimpleStatement ==> SimpleExpression
        SimpleStatement |=> SimpleExpression & ";"
        SimpleStatement |=> SimpleWhileStatement
        
        SimpleDeclaration ==> "var" & SimpleVariable & "=" & SimpleExpression
        
        SimpleExpression ==> SimpleDisjunction
        SimpleExpression |=> SimpleFuncall & SimpleAssignmentOperator & SimpleDisjunction
        
        SimpleDisjunction ==> SimpleConjunction & (SimpleDisjunctionOperator & SimpleConjunction)*
        
        SimpleConjunction ==> SimpleComparative & (SimpleConjunctionOperator & SimpleComparative)*
        
        SimpleComparative ==> SimpleAddition & (SimpleComparativeOperator & SimpleAddition)*
        
        SimpleAddition ==> SimpleTerm & (SimpleAdditionalOperator & SimpleTerm)*
        
        SimpleTerm ==> SimplePrefix & (SimpleMultiplicationOperator & SimplePrefix)*
        
        SimplePrefix ==> SimplePrefixOperator.opt & SimpleFuncall
        
        SimpleFuncall ==> SimpleFactor & (SimpleParameter)*
        SimpleFuncall |=> SimpleIfStatement
        
        SimpleParameter ==> "(" & SimpleExpression & ")"
        SimpleParameter |=> "." & SimpleVariable
        
        SimpleFactor ==> "(" & SimpleExpression & ")"
        SimpleFactor |=> SimpleVariable
        SimpleFactor |=> SimpleConstant
        
        SimpleConstant ==> SimpleNumericConstant | SimpleStringConstant
        
        SimpleBlock ==> "{" & SimpleStatement* & "}"
        
        SimpleIfStatement ==> "if" & SimpleExpression & SimpleBlock & ("else" & SimpleBlock).opt
        SimpleWhileStatement ==> "while" & SimpleExpression & SimpleBlock
    }
    
    override init(tokenizer: TokenizerBase<SimpleContext>) {
        super.init(tokenizer: tokenizer)
    }
}


