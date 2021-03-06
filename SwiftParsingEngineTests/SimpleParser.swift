//
//  SimpleParser.swift
//  SwiftParsingEngine
//
//  Created by 開発 on 2015/9/3.
//  Copyright © 2015-2017 OOPer (NAGATA, Atsuyuki). All rights reserved.
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

typealias SimpleNonTerminal = NonTerminalBase<SimpleState>
typealias SimpleTerminal = TerminalBase<SimpleState>


class SimpleParser: ParserBase<SimpleState> {
    
    //
    //MARK: Non terminal symbols
    //
    
    let SimpleScript = SimpleNonTerminal("Script") {match in
        let node = SimpleScriptNode()
        node.childNodes = match.nodes.filter{$0 is SimpleNode}
        return node
    }

    let SimpleStatement = SimpleNonTerminal("Statement") {match in
        return match.nodes.first!
    }
    let SimpleExpression = SimpleNonTerminal("Expression") {match in
        let nodes = match.nodes
        if nodes.count == 1 {
            return nodes[0]
        } else if nodes.count == 3 {
            let operation = (nodes[1] as! TerminalNode).token.string
            return SimpleBinaryNode(lhs: nodes[0], operation: operation, rhs: nodes[2])
        } else {
            fatalError("Parsing inconsistency error in SimpleExpression")
        }
    }
    let SimpleDeclaration = SimpleNonTerminal("Declaration") {match in
        let nodes = match.nodes
        assert(nodes.count == 4)
        return SimpleVariableDeclarationNode(variable: nodes[1], initial: nodes[3])
    }

    let SimpleIfStatement = SimpleNonTerminal("ifStatement") {match in
        let nodes = match.nodes
        assert(nodes.count == 3 || nodes.count == 5)
        let elseClause: NodeBase? = nodes.count == 5 ? nodes[4] : nil
        return SimpleIfNode(condition: nodes[1], ifClause: nodes[2], elseClause: elseClause)
    }
    
    let SimpleWhileStatement = SimpleNonTerminal("whileStatement") {match in
        let nodes = match.nodes
        assert(nodes.count == 3)
        return SimpleWhileNode(condition: nodes[1], codeBlock: nodes[2])
    }
    let SimpleDisjunction = SimpleNonTerminal("Disjunction") {SimpleBinaryNode.createWithNodes($0.nodes)}
    let SimpleConjunction = SimpleNonTerminal("Conjunction"){SimpleBinaryNode.createWithNodes($0.nodes)}
    let SimpleComparative = SimpleNonTerminal("Comparative") {SimpleBinaryNode.createWithNodes($0.nodes)}
    let SimpleAddition = SimpleNonTerminal("Addition") {SimpleBinaryNode.createWithNodes($0.nodes)}
    let SimpleTerm = SimpleNonTerminal("Term") {SimpleBinaryNode.createWithNodes($0.nodes)}
    
    let SimplePrefix = SimpleNonTerminal("Prefix") {match in
        let nodes = match.nodes
        if nodes.count == 1 {
            return nodes[0]
        } else if nodes.count == 2 {
            let operation = (nodes[0] as! TerminalNode).token.string
            return SimpleUnaryNode(operation: operation, argument: nodes[1])
        } else {
            fatalError("Parsing inconsistency error in SimplePrefix")
        }
    }
    
    let SimpleFuncall = SimpleNonTerminal("Funcall") {match in
        let nodes = match.nodes
        if nodes.count == 1 && nodes[0] is SimpleIfNode {
            return nodes[0]
        } else if nodes.count >= 1 {
            return SimpleFuncallNode.createWithNodes(nodes)
        } else {
            fatalError("Parsing inconsistency error in SimpleExpression")
        }
    }
    
    let SimpleParameter = SimpleNonTerminal("Parameter") {match in
        let nodes = match.nodes
        assert(nodes.count == 3 || nodes.count == 2)
        if nodes.count == 3 {
            return nodes[1]
        } else if nodes.count == 2 {
            return nodes[1]
        } else {
            fatalError("Parsing inconsistency error in SimpleParameter")
        }
    }
    
    let SimpleFactor = SimpleNonTerminal("Factor") {match in
        let nodes = match.nodes
        assert(nodes.count == 1 || nodes.count == 3)
        if nodes.count == 3 {
            return nodes[1]
        } else {
            assert(nodes[0] is TerminalNode)
            let tNode = nodes[0] as! TerminalNode
            if tNode.token is SimpleIdentifierToken {
                return SimpleVariableNode(name: tNode.token.string)
            } else if tNode.token is SimpleNumericLiteralToken {
                return SimpleNumericNode(string: tNode.token.string)
            } else if tNode.token is SimpleStringLiteralToken {
                return SimpleStringNode(token: tNode.token)
            } else {
                fatalError("Parsing inconsistency error in SimpleFactor")
            }
        }
    }
    
    let SimpleConstant = SimpleNonTerminal("Constant") {match in
        let nodes = match.nodes
        assert(nodes.count == 1)
        return nodes[0]
    }
    
    let SimpleBlock = SimpleNonTerminal("Block") {match in
        let node = SimpleBlockNode()
        node.childNodes = match.nodes.filter{$0 is SimpleNode}
        return node
    }
    
    //
    //MARK: Terminal symbols
    //
   
    let SimpleVariable = SimpleTerminal(SimpleIdentifierToken.self)
    let SimpleStringConstant = SimpleTerminal(SimpleStringLiteralToken.self)
    let SimpleNumericConstant = SimpleTerminal(SimpleNumericLiteralToken.self)
    let SimpleEnd = SimpleTerminal(EndToken.self)
    let SN = SimpleTerminal(SimpleNewlineToken.self)
    let SimpleAssignmentOperator = AnySymbol<SimpleState>("=", "+=", "-=", "*=", "/=", "^=", "&=", "|=", "<<=", ">>=", ">>>=", "??=")
    let SimpleDisjunctionOperator = AnySymbol<SimpleState>("||", "??")
    let SimpleConjunctionOperator = AnySymbol<SimpleState>("&&")
    let SimpleComparativeOperator = AnySymbol<SimpleState>("<", "<=", ">", ">=", "==", "!=", "===", "!==")
    let SimpleAdditionalOperator = AnySymbol<SimpleState>("+", "-", "|", "^")
    let SimpleMultiplicationOperator = AnySymbol<SimpleState>("*", "/", "&", "<<", ">>", ">>>")
    let SimplePrefixOperator = AnySymbol<SimpleState>("+", "-", "!", "~")

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
        
        SimpleBlock ==> "{" & (SN* & SimpleStatement)* & SN* & "}"
        
        SimpleIfStatement ==> "if" & SimpleExpression & SimpleBlock & ("else" & SimpleBlock).opt
        SimpleWhileStatement ==> "while" & SimpleExpression & SimpleBlock
    }

    var _state: SimpleState = SimpleState()

    override var state: SimpleState {
        get {
            _state.currentPosition = tokenizer.currentPosition
            return _state
        }
        set {
            _state = newValue
            tokenizer.currentPosition = _state.currentPosition
        }
    }

    override init(tokenizer: TokenizerBase<SimpleContext>) {
        super.init(tokenizer: tokenizer)
    }
 
}


