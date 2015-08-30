//
//  ParserBase.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/23.
//  Copyright © 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation

class SyntaxMatch<C: LexicalContextType, S: ParsingStateType where S.ContextType == C> {
    var nodes: [NodeBase]
    ///Parsing state after the match
    var state: S
    init(nodes: [NodeBase], state: S) {
        self.nodes = nodes
        self.state = state
    }
}
public class PatternBase<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C>: Token {
    
    init(_ string: String) {
        super.init(string, NSRange())
    }
    
    public var opt: OptPattern<C,S> {
        return OptPattern(pattern: self)
    }
    func or(pattern: PatternBase<C,S>)->AnyPattern<C,S> {
        if let anyPattern = pattern as? AnyPattern<C,S> {
            return AnyPattern([self] + anyPattern.patterns)
        } else {
            return AnyPattern([self, pattern])
        }
    }
    func concat(pattern: PatternBase<C,S>)->SequencePattern<C,S> {
        if let seqPattern = pattern as? SequencePattern<C,S> {
            return SequencePattern([self] + seqPattern.patterns)
        } else {
            return SequencePattern([self, pattern])
        }
    }
    
    func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        fatalError("Abstract method \(__FUNCTION__) not implemented")
    }
}

public class OptPattern<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C>: PatternBase<C,S> {
    var basePattern: PatternBase<C,S>
    init(pattern: PatternBase<C,S>) {
        self.basePattern = pattern
        super.init("")
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<C,S>] = []
        result += basePattern.match(parser)
        result.append(SyntaxMatch(nodes: [], state: savedState))
        parser.state = savedState
        return result
    }
}

public class AnyPattern<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C>: PatternBase<C,S> {
    var patterns: [PatternBase<C,S>]
    init(_ patterns: [PatternBase<C,S>]) {
        self.patterns = patterns
        super.init("")
    }
    override func or(pattern: PatternBase<C,S>)->AnyPattern<C,S> {
        if let anyPattern = pattern as? AnyPattern<C,S> {
            return AnyPattern(self.patterns + anyPattern.patterns)
        } else {
            return AnyPattern(self.patterns + [pattern])
        }
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
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
where C.Element == C, S.ContextType == C>: PatternBase<C,S> {
    ///
    var pattern: PatternBase<C,S>? = nil
    func addPattern(pattern: PatternBase<C,S>) {
        self.pattern = self.pattern?.or(pattern) ?? pattern
    }
    //???
    var nodeType: NodeBase.Type
    public init(_ nodeType: NodeBase.Type) {
        self.nodeType = nodeType
        super.init(NSStringFromClass(nodeType))
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        guard let pattern = self.pattern else {fatalError("match called before definition")}
        let matches = pattern.match(parser)
        return matches.map {match in
            let nodes = [nodeType.createNode(match.nodes)]
            let state = match.state
            return SyntaxMatch(nodes: nodes, state: state)
        }
    }
}

public class TerminalBase<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C>: PatternBase<C,S> {
    var type: Token.Type? = nil
    public init(_ type: Token.Type) {
        self.type = type
        super.init("")
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<C,S>] = []
        do {
            let token = try parser.tokenizer.getToken()
            if token.dynamicType == self.type {
                let nodes: [NodeBase] = [TerminalNode(token: token)]
                result = [SyntaxMatch(nodes: nodes, state: parser.state)]
            }
        } catch _  {
            fatalError()
        }
        parser.state = savedState
        return result
    }
}

public class Symbol<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C>: PatternBase<C,S>, StringLiteralConvertible {
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
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<C,S>] = []
        do {
            let token = try parser.tokenizer.getToken()
            if token.string == self.string {
                let nodes: [NodeBase] = [TerminalNode(token: token)]
                result = [SyntaxMatch(nodes: nodes, state: parser.state)]
            }
        } catch _  {
            fatalError()
        }
        parser.state = savedState
        return result
    }
}

class ToStateBase<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C>:  PatternBase<C,S> {
    var context: C
    init(_ context: C) {
        self.context = context
        super.init(String(context))
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        parser.tokenizer.currentContext = self.context
        let result: [SyntaxMatch<C,S>] = [SyntaxMatch(nodes: [], state: parser.state)]
        parser.state = savedState
        return result
    }
}

public class SequencePattern<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C>: PatternBase<C,S> {
    var patterns: [PatternBase<C,S>]
    init(_ patterns: [PatternBase<C,S>]) {
        self.patterns = patterns
        super.init("")
    }
    override func concat(pattern: PatternBase<C,S>)->SequencePattern<C,S> {
        if let seqPattern = pattern as? SequencePattern<C,S> {
            return SequencePattern(self.patterns + seqPattern.patterns)
        } else {
            return SequencePattern(self.patterns + [pattern])
        }
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<C,S>] = [SyntaxMatch(nodes: [], state: savedState)]
        for pattern in patterns {
            var updatedResult: [SyntaxMatch<C,S>] = []
            for match in result {
                parser.state = match.state
                let nextMatches = pattern.match(parser)
                for nextMatch in nextMatches {
                    let nodes = match.nodes + nextMatch.nodes
                    let state = nextMatch.state
                    updatedResult.append(SyntaxMatch(nodes: nodes, state: state))
                }
            }
            result = updatedResult
        }
        parser.state = savedState
        return result
    }
}

public class RepeatPattern<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C>: PatternBase<C,S> {
    var pattern: PatternBase<C,S>
    var minCount: Int = 0
    init(_ pattern: PatternBase<C,S>) {
        self.pattern = pattern
        super.init("")
    }
    init(_ pattern: PatternBase<C,S>, minCount: Int) {
        self.pattern = pattern
        self.minCount = minCount
        super.init("")
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        var lastMatches: [SyntaxMatch<C,S>] = [SyntaxMatch(nodes: [], state: savedState)]
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
                    updatedResult.append(SyntaxMatch(nodes: nodes, state: state))
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

infix operator |=> {precedence 90}
public func |=> <C: LexicalContextType, S: ParsingStateType
    where C.Element == C, S.ContextType == C>(lhs: NonTerminalBase<C,S>, rhs: PatternBase<C,S>) {
    lhs.addPattern(rhs)
}
public func | <C: LexicalContextType, S: ParsingStateType
    where C.Element == C, S.ContextType == C>(lhs: PatternBase<C,S>, rhs: PatternBase<C,S>)->AnyPattern<C,S> {
    return lhs.or(rhs)
}
infix operator ~ {}
public func & <C: LexicalContextType, S: ParsingStateType
    where C.Element == C, S.ContextType == C>(lhs: Symbol<C,S>, rhs: Symbol<C,S>)->SequencePattern<C,S> {
    return lhs.concat(rhs)
}
public func & <C: LexicalContextType, S: ParsingStateType
    where C.Element == C, S.ContextType == C>(lhs: PatternBase<C,S>, rhs: Symbol<C,S>)->SequencePattern<C,S> {
    return lhs.concat(rhs)
}
public func & <C: LexicalContextType, S: ParsingStateType
    where C.Element == C, S.ContextType == C>(lhs: Symbol<C,S>, rhs: PatternBase<C,S>)->SequencePattern<C,S> {
    return lhs.concat(rhs)
}
public func & <C: LexicalContextType, S: ParsingStateType
    where C.Element == C, S.ContextType == C>(lhs: PatternBase<C,S>, rhs: PatternBase<C,S>)->SequencePattern<C,S> {
    return lhs.concat(rhs)
}

postfix operator + {}
postfix operator * {}

public postfix func + <C: LexicalContextType, S: ParsingStateType
    where C.Element == C, S.ContextType == C>(pattern: PatternBase<C,S>) -> RepeatPattern<C,S> {
    return RepeatPattern<C,S>(pattern, minCount: 1)
}

public postfix func * <C: LexicalContextType, S: ParsingStateType
    where C.Element == C, S.ContextType == C>(pattern: PatternBase<C,S>) -> RepeatPattern<C,S> {
    return RepeatPattern<C,S>(pattern)
}

public protocol ParsingStateType {
    typealias ContextType: LexicalContextType
    var context: ContextType {get}
    init()
}
public class ParserBase<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C> {
    public var tokenizer: TokenizerBase<C>
    public var state: S = S()
    public func setup() {
        fatalError("Abstract method \(__FUNCTION__) not implemented")
    }
    
    public init(tokenizer: TokenizerBase<C>) {
        self.tokenizer = tokenizer
        self.setup()
    }
    
    public func parse(nt: NonTerminalBase<C,S>) -> NodeBase? {
        assert(nt.pattern != nil)
        let matches = nt.pattern!.match(self)
        if matches.count > 1 {
            
        }
        return nil
    }
}
