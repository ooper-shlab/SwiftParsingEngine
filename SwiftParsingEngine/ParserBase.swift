//
//  ParserBase.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/23.
//  Copyright © 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation

public class SyntaxMatch<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C> {
    public var pattern: PatternBase
    public var nodes: [NodeBase]
    ///Parsing state after the match
    public var state: S
    init(pattern: PatternBase, nodes: [NodeBase], state: S) {
        self.pattern = pattern
        self.nodes = nodes
        self.state = state
    }
}

public class PatternBase {
    public var string: String
    public init(_ string: String) {
        self.string = string
    }
    public init() {
        self.string = String(self.dynamicType)
    }
    
    //MARK: extensions to use Token as Pattern
    func or(pattern: PatternBase)->AnyPattern {
        if let anyPattern = pattern as? AnyPattern {
            return AnyPattern([self] + anyPattern.patterns)
        } else {
            return AnyPattern([self, pattern])
        }
    }
    
    func concat(pattern: PatternBase)->SequencePattern {
        if let seqPattern = pattern as? SequencePattern {
            return SequencePattern([self] + seqPattern.patterns)
        } else {
            return SequencePattern([self, pattern])
        }
    }
    
    func match<C: LexicalContextType, S: ParsingStateType
        where C.Element == C, S.ContextType == C>(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
            fatalError("Abstract method \(__FUNCTION__) not implemented")
    }
    
    public var opt: OptPattern {
        return OptPattern(pattern: self)
    }
}

public class OptPattern: PatternBase {
    var basePattern: PatternBase
    init(pattern: PatternBase) {
        self.basePattern = pattern
        super.init()
    }
    
    override func match<C: LexicalContextType, S: ParsingStateType
        where C.Element == C, S.ContextType == C>(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<C,S>] = []
        result += basePattern.match(parser)
        result.append(SyntaxMatch(pattern: self, nodes: [], state: savedState))
        parser.state = savedState
        return result
    }
}

public class AnyPattern: PatternBase {
    var patterns: [PatternBase]
    init(_ patterns: [PatternBase]) {
        self.patterns = patterns
        super.init()
    }
    override func or(pattern: PatternBase)->AnyPattern {
        if let anyPattern = pattern as? AnyPattern {
            return AnyPattern(self.patterns + anyPattern.patterns)
        } else {
            return AnyPattern(self.patterns + [pattern])
        }
    }
    
    override func match<C: LexicalContextType, S: ParsingStateType
        where C.Element == C, S.ContextType == C>(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<C,S>] = []
        for pattern in patterns {
            result += pattern.match(parser)
            parser.state = savedState
        }
        return result
    }
}

public class NonTerminalBase<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C, C: Hashable>: PatternBase {
    public typealias NodeConstructorType = SyntaxMatch<C,S> -> NodeBase
    
    public var nodeConstructor: NodeConstructorType?
    ///
    var pattern: PatternBase? = nil

    public init(nodeConstructor: NodeConstructorType) {
        self.nodeConstructor = nodeConstructor
        super.init()
    }
    
    func addPattern(pattern: PatternBase) {
        self.pattern = self.pattern?.or(pattern) ?? pattern
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        guard let pattern = self.pattern
            ,nodeConstructor = self.nodeConstructor else {fatalError("match called before definition")}
        let matches = pattern.match(parser)
        return matches.map {match in
            let nodes = [nodeConstructor(match)]
            let state = match.state
            return SyntaxMatch(pattern: self, nodes: nodes, state: state)
        }
    }
}

public class Terminal: PatternBase {
    var type: Token.Type? = nil
    var predicate: String->Bool
    
    public init(_ type: Token.Type) {
        self.type = type
        self.predicate = {_ in true}
        super.init()
    }
    init(_ type: Token.Type, _ predicate: String->Bool) {
        self.type = type
        self.predicate = predicate
        super.init()
    }
    public convenience init(_ type: Token.Type, _ names: String...) {
        let nameSet = Set(names)
        self.init(type) {nameSet.contains($0)}
    }
    
    override func match<C: LexicalContextType, S: ParsingStateType
        where C.Element == C, S.ContextType == C>(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<C,S>] = []
        do {
            let token = try parser.tokenizer.getToken()
            //print("matching \(token.string.debugDescription) to \(self.type!)")
            if token.dynamicType == self.type {
                let nodes: [NodeBase] = [TerminalNode(token: token)]
                result = [SyntaxMatch(pattern: self, nodes: nodes, state: parser.state)]
                //print("-->succeeded")
            } else {
                //print("-->failed")
            }
        } catch _  {
            fatalError()
        }
        parser.state = savedState
        return result
    }
}

public class Symbol: PatternBase, StringLiteralConvertible {
    override init(_ string: String) {
        super.init(string)
    }
    required public init(extendedGraphemeClusterLiteral value: String) {
        super.init(value)
    }
    required public init(stringLiteral value: String) {
        super.init(value)
    }
    required public init(unicodeScalarLiteral value: String) {
        super.init(value)
    }
    
    override func match<C: LexicalContextType, S: ParsingStateType
        where C.Element == C, S.ContextType == C>(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<C,S>] = []
        do {
            let token = try parser.tokenizer.getToken()
            if token.string == self.string {
                let nodes: [NodeBase] = [TerminalNode(token: token)]
                result = [SyntaxMatch(pattern: self, nodes: nodes, state: parser.state)]
            }
        } catch _  {
            fatalError()
        }
        parser.state = savedState
        return result
    }
}

public class AnySymbol: PatternBase {
    var strings: Set<String>
    
    public init(_ strings: String...) {
        assert(strings.count > 0)
        self.strings = Set(strings)
        super.init(strings.first!)
    }
    
    override func match<C: LexicalContextType, S: ParsingStateType
        where C.Element == C, S.ContextType == C>(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<C,S>] = []
        do {
            let token = try parser.tokenizer.getToken()
            if self.strings.contains(token.string) {
                let nodes: [NodeBase] = [TerminalNode(token: token)]
                result = [SyntaxMatch(pattern: self, nodes: nodes, state: parser.state)]
            }
        } catch _  {
            fatalError()
        }
        parser.state = savedState
        return result
    }
}

class ToStateBase<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C, C: Hashable>:  PatternBase {
    var context: C
    init(_ context: C) {
        self.context = context
        super.init(String(context))
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        parser.tokenizer.currentContext = self.context
        let result: [SyntaxMatch<C,S>] = [SyntaxMatch(pattern: self, nodes: [], state: parser.state)]
        parser.state = savedState
        return result
    }
}

public class SequencePattern: PatternBase {
    
    var patterns: [PatternBase]
    
    init(_ patterns: [PatternBase]) {
        self.patterns = patterns
        super.init("")
    }
    
    override func concat(pattern: PatternBase)->SequencePattern {
        if let seqPattern = pattern as? SequencePattern {
            return SequencePattern(self.patterns + seqPattern.patterns)
        } else {
            return SequencePattern(self.patterns + [pattern])
        }
    }
    
    override func match<C: LexicalContextType, S: ParsingStateType
        where C.Element == C, S.ContextType == C>(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<C,S>] = [SyntaxMatch(pattern: self, nodes: [], state: savedState)]
        for pattern in patterns {
            var updatedResult: [SyntaxMatch<C,S>] = []
            for match in result {
                parser.state = match.state
                let nextMatches = pattern.match(parser)
                for nextMatch in nextMatches {
                    let nodes = match.nodes + nextMatch.nodes
                    let state = nextMatch.state
                    updatedResult.append(SyntaxMatch(pattern: self, nodes: nodes, state: state))
                }
            }
            result = updatedResult
        }
        parser.state = savedState
        return result
    }
}

public class RepeatPattern: PatternBase {
    var pattern: PatternBase
    var minCount: Int = 0
    init(_ pattern: PatternBase) {
        self.pattern = pattern
        super.init("")
    }
    init(_ pattern: PatternBase, minCount: Int) {
        self.pattern = pattern
        self.minCount = minCount
        super.init("")
    }
    
    override func match<C: LexicalContextType, S: ParsingStateType
        where C.Element == C, S.ContextType == C>(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        var lastMatches: [SyntaxMatch<C,S>] = [SyntaxMatch(pattern: self, nodes: [], state: savedState)]
        var result: [SyntaxMatch<C,S>] = []
        outer: for var i = 0;; ++i {
            if i >= minCount {
                result += lastMatches
            }
            var updatedResult: [SyntaxMatch<C,S>] = []
            for lastMatch in lastMatches {
                parser.state = lastMatch.state
                let nextMatches = pattern.match(parser)
                for nextMatch in nextMatches {
                    let nodes = lastMatch.nodes + nextMatch.nodes
                    let state = nextMatch.state
                    updatedResult.append(SyntaxMatch(pattern: self, nodes: nodes, state: state))
                }
            }
            if updatedResult.isEmpty {
                break outer
            }
            lastMatches = updatedResult
        }
        parser.state = savedState
        return result
    }
}

infix operator ==> {precedence 90}
public func ==> <C: LexicalContextType, S: ParsingStateType
    where C.Element == C, S.ContextType == C>(lhs: NonTerminalBase<C,S>, rhs: PatternBase) {
        lhs.pattern = rhs
}

infix operator |=> {precedence 90}
public func |=> <C: LexicalContextType, S: ParsingStateType
    where C.Element == C, S.ContextType == C>(lhs: NonTerminalBase<C,S>, rhs: PatternBase) {
    lhs.addPattern(rhs)
}
public func | (lhs: PatternBase, rhs: PatternBase)->AnyPattern {
    return lhs.or(rhs)
}

public func & (lhs: Symbol, rhs: Symbol)->SequencePattern {
    return lhs.concat(rhs)
}
public func & (lhs: PatternBase, rhs: Symbol)->SequencePattern {
    return lhs.concat(rhs)
}
public func & (lhs: Symbol, rhs: PatternBase)->SequencePattern {
    return lhs.concat(rhs)
}
public func & (lhs: PatternBase, rhs: PatternBase)->SequencePattern {
    return lhs.concat(rhs)
}

postfix operator + {}
postfix operator * {}

public postfix func + (pattern: PatternBase) -> RepeatPattern {
    return RepeatPattern(pattern, minCount: 1)
}

public postfix func * (pattern: PatternBase) -> RepeatPattern {
    return RepeatPattern(pattern)
}

public protocol ParsingStateType {
    typealias ContextType: LexicalContextType
    var context: ContextType {get}
    init()
}
public class ParserBase<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C, C: Hashable> {
    public var tokenizer: TokenizerBase<C>
    public var state: S = S()
    public func setup() {
        fatalError("Abstract method \(__FUNCTION__) not implemented")
    }
    
    public init(tokenizer: TokenizerBase<C>) {
        self.tokenizer = tokenizer
        tokenizer.reset()
        self.setup()
        //TODO: current parsing is too slow, needs compilation & optimization here...
    }
    
    public func reset() {
        tokenizer.reset()
        state = S()
    }
    
    public func parse(nt: NonTerminalBase<C,S>) -> NodeBase? {
        assert(nt.pattern != nil && nt.nodeConstructor != nil)
        let matches = nt.pattern!.match(self)
        if matches.count > 0 {
            //First match only, as for now
            return nt.nodeConstructor!(matches.first!)
        } else {
            return nil
        }
    }
}
