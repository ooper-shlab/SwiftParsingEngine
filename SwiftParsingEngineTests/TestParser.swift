//
//  Parser.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/23.
//  Copyright (c) 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation
import SwiftParsingEngine

struct ParsingState: ParsingStateType {
    var context: LexicalContext
    var contextStack: [LexicalContext] = []
    var currentPosition: Int
    var tagName: String
    init() {
        context = LexicalContext.Initial
        contextStack = []
        currentPosition = 0
        tagName = String()
    }
}

class NonTerminal: NonTerminalBase<LexicalContext, ParsingState> {
    override init(nodeConstructor: NodeConstructorType) {
        super.init(nodeConstructor :nodeConstructor)
    }
}

class Parser: ParserBase<LexicalContext, ParsingState> {
    
    //MARK: Non terminal symbols
    let Template = NonTerminal{_ in RootNode()}
    let Statement = NonTerminal{_ in StatementNode()}
    let Block = NonTerminal{_ in BlockNode()}
    let Expression = NonTerminal{_ in ExpressionNode()}
    let PrefixExpression = NonTerminal{_ in PrefixExpressionNode()}
    let BinaryExpression = NonTerminal{_ in BinaryExpressionNode()}
    let IfStatement = NonTerminal{_ in IfStatementNode()}
    let ForStatement = NonTerminal{_ in ForStatementNode()}
    let HTMLOutputStatement = NonTerminal{match in HTMLOutputNode.createNode(match.nodes)}
    
    //MARK: Terminal symbols
    let PrefixOperator = Terminal(OperatorToken.self, "&", "+", "-", "!", "~")
    let HTMLText = Terminal(HTMLTextToken)
    let N = Terminal(NewLine)
    
    override func setup() {
        Template |=> Statement+
        Statement |=> Expression | ForStatement | IfStatement | HTMLOutputStatement
        Expression |=> PrefixExpression & BinaryExpression.opt
        PrefixExpression |=> PrefixOperator* & PrefixExpression
        HTMLOutputStatement |=> N* & HTMLText
    }
    
    var _state: ParsingState = ParsingState()
    override var state: ParsingState {
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
    
    override init(tokenizer: TokenizerBase<LexicalContext>) {
        super.init(tokenizer: tokenizer)
    }
}
