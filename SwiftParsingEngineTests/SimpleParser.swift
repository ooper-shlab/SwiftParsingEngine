//
//  SimpleParser.swift
//  SwiftParsingEngine
//
//  Created by 開発 on 2015/9/3.
//  Copyright © 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation
import SwiftParsingEngine


struct SimpleState: ParsingStateType {
    var context: SimpleContext
    var contextStack: [SimpleContext] = []
    var currentPosition: Int
    var tagName: String
    init() {
        context = SimpleContext.Initial
        contextStack = []
        currentPosition = 0
        tagName = String()
    }
}

class SimpleNonTerminal: NonTerminalBase<SimpleContext, SimpleState> {
    override init(nodeConstructor: NodeConstructorType) {
        super.init(nodeConstructor :nodeConstructor)
    }
}

class SimpleTerminal: TerminalBase<SimpleContext, SimpleState> {
    var predicate: String->Bool
    override init(_ type: Token.Type) {
        self.predicate = {_ in true}
        super.init(type)
    }
    init(_ type: Token.Type, _ predicate: String->Bool) {
        self.predicate = predicate
        super.init(type)
    }
    convenience init(_ type: Token.Type, _ names: String...) {
        let nameSet = Set(names)
        self.init(type) {nameSet.contains($0)}
    }
}


//MARK: Non terminal symbols
let SimpleScript = SimpleNonTerminal{_ in SimpleScriptNode()}
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

let SimpleVariable = SimpleTerminal(SimpleIdentifierToken)
let SimpleStringConstant = SimpleTerminal(SimpleStringLiteralToken)
let SimpleNumericConstant = SimpleTerminal(SimpleNumericLiteralToken)
let SimpleAssignmentOperator = AnySymbol<SimpleContext, SimpleState>("=", "+=", "-=", "*=", "/=", "^=", "&=", "|=", "<<=", ">>=", ">>>=", "??=")
let SimpleDisjunctionOperator = AnySymbol<SimpleContext, SimpleState>("||", "??")
let SimpleConjunctionOperator = AnySymbol<SimpleContext, SimpleState>("&&")
let SimpleComparativeOperator = AnySymbol<SimpleContext, SimpleState>("<", "<=", ">", ">=", "==", "!=", "===", "!==")
let SimpleAdditionalOperator = AnySymbol<SimpleContext, SimpleState>("+", "-", "|", "^")
let SimpleMultiplicationOperator = AnySymbol<SimpleContext, SimpleState>("*", "/", "&", "<<", ">>", ">>>")
let SimplePrefixOperator = AnySymbol<SimpleContext, SimpleState>("+", "-", "!", "~")

let SimpleBlock = SimpleNonTerminal{_ in SimpleBlockNode()}

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
        SimpleScript |=> (SimpleStatement | SimpleDeclaration)*
        
        SimpleStatement |=> SimpleExpression
        SimpleStatement |=> SimpleExpression & ";"
        SimpleStatement |=> SimpleWhileStatement
        
        SimpleExpression |=> SimpleDisjunction
        SimpleExpression |=> SimpleVariable & SimpleAssignmentOperator & SimpleDisjunction
        
        SimpleDisjunction |=> SimpleConjunction & (SimpleDisjunctionOperator & SimpleConjunction)*
        
        SimpleConjunction |=> SimpleComparative & SimpleConjunctionOperator & SimpleComparative
        
        SimpleComparative |=> SimpleAddition & (SimpleComparativeOperator & SimpleAddition)*
        
        SimpleAddition |=> SimpleTerm & (SimpleAdditionalOperator & SimpleTerm)*
        
        SimpleTerm |=> SimplePrefix & (SimpleMultiplicationOperator & SimplePrefix)*
        
        SimplePrefix |=> SimplePrefixOperator.opt & SimpleFuncall
        
        SimpleFuncall |=> SimpleFactor & (SimpleParameter)*
        SimpleFuncall |=> SimpleIfStatement
        
        SimpleParameter |=> "(" & SimpleExpression & ")"
        SimpleParameter |=> "." & SimpleVariable
        
        SimpleFactor |=> "(" & SimpleExpression & ")"
        SimpleFactor |=> SimpleVariable
        SimpleFactor |=> SimpleConstant
        
        SimpleConstant |=> SimpleNumericConstant | SimpleStringConstant
        
        SimpleBlock |=> "{" & SimpleStatement* & "}"
        
        SimpleIfStatement |=> "if" & SimpleExpression & SimpleBlock & ("else" & SimpleBlock).opt
        SimpleWhileStatement |=> "while" & SimpleExpression & SimpleBlock
    }
    
    override init(tokenizer: TokenizerBase<SimpleContext>) {
        super.init(tokenizer: tokenizer)
    }
}


