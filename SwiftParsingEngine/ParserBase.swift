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
    public var pattern: PatternBase<C,S>
    public var nodes: [NodeBase]
    ///Parsing state after the match
    public var state: S
    public init(pattern: PatternBase<C,S>, nodes: [NodeBase], state: S) {
        self.pattern = pattern
        self.nodes = nodes
        self.state = state
    }
}

public class PatternBase<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C> {
    public var string: String
    public init(_ string: String) {
        self.string = string
    }
    public init() {
        self.string = String(self.dynamicType)
    }
    
    // MARK: extensions to use Token as Pattern
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
    
    public var opt: OptPattern<C,S> {
        return OptPattern(pattern: self)
    }
}

public class OptPattern<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C>: PatternBase<C,S> {
    var basePattern: PatternBase<C,S>
    init(pattern: PatternBase<C,S>) {
        self.basePattern = pattern
        super.init()
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<C,S>] = []
        result += basePattern.match(parser)
        result.append(SyntaxMatch(pattern: self, nodes: [], state: savedState))
        parser.state = savedState
        return result
    }
}

public class AnyPattern<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C>: PatternBase<C,S> {
    var patterns: [PatternBase<C,S>]
    init(_ patterns: [PatternBase<C,S>]) {
        self.patterns = patterns
        super.init()
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

public class FailPattern<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C>: PatternBase<C,S> {
    public override init() {
        super.init()
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
            return []
    }
}

public class NonTerminalBase<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C, C: Hashable>: PatternBase<C,S> {
    public typealias NodeConstructorType = SyntaxMatch<C,S> -> NodeBase
    
    public var nodeConstructor: NodeConstructorType?
    ///
    var pattern: PatternBase<C,S>? = nil
    ///Debuggin: report matches
    public var shouldReportMatches: Bool = false
    ///Debuggin: report tests
    public var shouldReportTests: Bool = false
    

    public init(nodeConstructor: NodeConstructorType) {
        self.nodeConstructor = nodeConstructor
        super.init()
    }
    
    public init(_ name: String, nodeConstructor: NodeConstructorType) {
        self.nodeConstructor = nodeConstructor
        super.init(name)
    }
    
    public override init(_ name: String) {
        super.init(name)
    }
    
    func addPattern(pattern: PatternBase<C,S>) {
        self.pattern = self.pattern?.or(pattern) ?? pattern
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        guard let pattern = self.pattern else {fatalError("match called before definition")}
        if nodeConstructor == nil {nodeConstructor = DefaultNodeConstructor}
        if shouldReportTests {
            print("\(string) about to start testing")
        }
        let matches = pattern.match(parser)
        if (shouldReportMatches || shouldReportTests) && !matches.isEmpty {
            print("\(string) found matches(\(matches.count))")
        }
        if shouldReportTests {
            if matches.isEmpty {
                print("\(string) testing failed")
            }
            print("\(string) end testing")
        }
        return matches.map {match in
            let nodes = [nodeConstructor!(match)]
            let state = match.state
            return SyntaxMatch(pattern: self, nodes: nodes, state: state)
        }
    }
}
///Intended to use while Syntax debugging
class PlainNode<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C, C: Hashable>: NodeBase {
    let match: SyntaxMatch<C,S>
    init(match: SyntaxMatch<C,S>) {
        self.match = match
    }
}
///Intended to use while Syntax debugging
func DefaultNodeConstructor<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C, C: Hashable>(match: SyntaxMatch<C,S>) -> NodeBase {
    return PlainNode(match: match)
}

public class TerminalBase<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C>: PatternBase<C,S> {
    public var type: Token.Type? = nil
    var predicate: String->Bool
    
    public init(_ type: Token.Type) {
        self.type = type
        self.predicate = {_ in true}
        super.init()
    }
    public init(type: Token.Type, _ predicate: String->Bool) {
        self.type = type
        self.predicate = predicate
        super.init()
    }
    public convenience init(type: Token.Type, _ names: String...) {
        let nameSet = Set(names)
        self.init(type: type) {nameSet.contains($0)}
    }
    
    override public func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<C,S>] = []
        do {
            let token = try parser.tokenizer.getToken(parser.state.context)
            //print("matching \(token.string.debugDescription) to \(self.type!)")
            if token.dynamicType == self.type {
                let nodes: [NodeBase] = [TerminalNode(token: token)]
                result = [SyntaxMatch(pattern: self, nodes: nodes, state: parser.state)]
                //print("\(self.type!)-->succeeded \(token.string.debugDescription)")
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

public class Symbol<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C>: PatternBase<C,S>, StringLiteralConvertible {
//    override init(_ string: String) {
//        super.init(string)
//    }
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
            let token = try parser.tokenizer.getToken(parser.state.context)
            //print("matching \(token.string.debugDescription) to \(self.string)")
            if token.string == self.string {
                let nodes: [NodeBase] = [TerminalNode(token: token)]
                result = [SyntaxMatch(pattern: self, nodes: nodes, state: parser.state)]
                //print("\(string.debugDescription)-->succeeded \(token.string.debugDescription)")
            } else {
                //print("-->failed")
            }
        } catch let error {
            print(error)
            fatalError(self.string.debugDescription)
        }
        parser.state = savedState
        return result
    }
}

public class AnySymbol<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C>: PatternBase<C,S> {
    var strings: Set<String>
    
    public init(_ strings: String...) {
        assert(strings.count > 0)
        self.strings = Set(strings)
        super.init(strings.first!)
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<C,S>] = []
        do {
            let token = try parser.tokenizer.getToken(parser.state.context)
            //print("matching \(token.string.debugDescription) to \(self.strings.debugDescription)")
            if self.strings.contains(token.string) {
                let nodes: [NodeBase] = [TerminalNode(token: token)]
                result = [SyntaxMatch(pattern: self, nodes: nodes, state: parser.state)]
                //print("\(strings.debugDescription)-->succeeded \(token.string.debugDescription)")
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

public class SetState<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C, C: Hashable>:  PatternBase<C,S> {
    var context: C
    public init(_ context: C) {
        self.context = context
        super.init(String(context))
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        parser.state.context = self.context
        let result: [SyntaxMatch<C,S>] = [SyntaxMatch(pattern: self, nodes: [], state: parser.state)]
        return result
    }
}
public class PushAndSetState<C: LexicalContextType, S: StackableParsingState
where C.Element == C, S.ContextType == C, C: Hashable>:  PatternBase<C,S> {
    var context: C
    var extraInfo: S.ExtraInfoType?
    public init(_ context: C) {
        self.context = context
        super.init(String(context))
    }
    public init(_ context: C, extraInfo: S.ExtraInfoType) {
        self.context = context
        self.extraInfo = extraInfo
        super.init(String(context))
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        parser.state.pushAndSet(self.context, newExtraInfo: self.extraInfo)
        let result: [SyntaxMatch<C,S>] = [SyntaxMatch(pattern: self, nodes: [], state: parser.state)]
        return result
    }
}
public class PopState<C: LexicalContextType, S: StackableParsingState
where C.Element == C, S.ContextType == C, C: Hashable>:  PatternBase<C,S> {
    public override init() {
        super.init("PopState")
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
        parser.state.pop()
        let result: [SyntaxMatch<C,S>] = [SyntaxMatch(pattern: self, nodes: [], state: parser.state)]
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
        if let seqPattern = pattern as? SequencePattern {
            return SequencePattern(self.patterns + seqPattern.patterns)
        } else {
            return SequencePattern(self.patterns + [pattern])
        }
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
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

///Non-backtracking locally maximum-length repeat
public class LocalMaximumRepeatPattern<C: LexicalContextType, S: ParsingStateType
where C.Element == C, S.ContextType == C>: RepeatPattern<C,S> {
    override init(_ pattern: PatternBase<C, S>) {
        super.init(pattern)
    }
    override init(_ pattern: PatternBase<C, S>, minCount: Int) {
        super.init(pattern, minCount: minCount)
    }
    
    override func match(parser: ParserBase<C,S>) -> [SyntaxMatch<C,S>] {
            let savedState = parser.state
            var lastMatches: [SyntaxMatch<C,S>] = [SyntaxMatch(pattern: self, nodes: [], state: savedState)]
            var result: [SyntaxMatch<C,S>] = []
            outer: for var i = 0;; ++i {
                if i >= minCount {
                    result = lastMatches
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
    where C.Element == C, S.ContextType == C>(lhs: NonTerminalBase<C,S>, rhs: PatternBase<C,S>) {
        lhs.pattern = rhs
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
postfix operator +-> {}
postfix operator * {}
postfix operator *-> {}

public postfix func + <C: LexicalContextType, S: ParsingStateType
    where C.Element == C, S.ContextType == C>(pattern: PatternBase<C,S>) -> RepeatPattern<C,S> {
    return RepeatPattern(pattern, minCount: 1)
}

public postfix func * <C: LexicalContextType, S: ParsingStateType
    where C.Element == C, S.ContextType == C>(pattern: PatternBase<C,S>) -> RepeatPattern<C,S> {
    return RepeatPattern(pattern)
}

public postfix func +-> <C: LexicalContextType, S: ParsingStateType
    where C.Element == C, S.ContextType == C>(pattern: PatternBase<C,S>) -> LocalMaximumRepeatPattern<C,S> {
    return LocalMaximumRepeatPattern(pattern, minCount: 1)
}

public postfix func *-> <C: LexicalContextType, S: ParsingStateType
    where C.Element == C, S.ContextType == C>(pattern: PatternBase<C,S>) -> LocalMaximumRepeatPattern<C,S> {
    return LocalMaximumRepeatPattern(pattern)
}

public protocol ParsingStateType {
    typealias ContextType: LexicalContextType
    var context: ContextType {get set}
    init()
}
public protocol StackableParsingState: ParsingStateType {
    ///Extra information type saved in stack with ContextType
    typealias ExtraInfoType
    mutating func pushAndSet(newContext: ContextType)
    ///Use default if newExtraInfo == nil
    mutating func pushAndSet(newContext: ContextType, newExtraInfo: ExtraInfoType?)
    mutating func pop()
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
