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
    override init(_ nodeType: NodeBase.Type) {
        super.init(nodeType)
    }
}

class Terminal: TerminalBase<LexicalContext, ParsingState> {
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
let Template = NonTerminal(RootNode)
let Statement = NonTerminal(StatementNode)
let Block = NonTerminal(BlockNode)
let Expression = NonTerminal(ExpressionNode)
let PrefixExpression = NonTerminal(PrefixExpressionNode)
let BinaryExpression = NonTerminal(BinaryExpressionNode)
let IfStatement = NonTerminal(IfStatementNode)
let ForStatement = NonTerminal(ForStatementNode)
let HTMLOutputStatement = NonTerminal(HTMLOutputNode)

//MARK: Terminal symbols
let PrefixOperator = Terminal(OperatorToken.self, "&", "+", "-", "!", "~")
let HTMLText = Terminal(HTMLTextToken)
let N = Terminal(NewLine)


class Parser: ParserBase<LexicalContext, ParsingState> {
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
    override func setup() {
        Template |=> Statement+
        Statement |=> Expression | ForStatement | IfStatement | HTMLOutputStatement
        Expression |=> PrefixExpression & BinaryExpression.opt
        PrefixExpression |=> PrefixOperator* & PrefixExpression
        HTMLOutputStatement |=> N* & HTMLText
    }
    
    override init(tokenizer: TokenizerBase<LexicalContext>) {
        super.init(tokenizer: tokenizer)
    }
}
