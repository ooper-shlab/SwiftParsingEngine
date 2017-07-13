//
//  ParserBase.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/23.
//  Copyright © 2015−2017 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation

open class SyntaxMatch<S: ParsingStateType> {
    open var pattern: PatternBase<S>
    open var nodes: [NodeBase]
    ///Parsing state after the match
    open var state: S
    public init(pattern: PatternBase<S>, nodes: [NodeBase], state: S) {
        self.pattern = pattern
        self.nodes = nodes
        self.state = state
    }
}

open class PatternBase<S: ParsingStateType> {
    private typealias C = S.ContextType
    open var string: String
    public init(_ string: String) {
        self.string = string
    }
    public init() {
        self.string = String(describing: type(of: self))
    }
    
    // MARK: extensions to use Token as Pattern
    func or(_ pattern: PatternBase<S>)->AnyPattern<S> {
        if let anyPattern = pattern as? AnyPattern<S> {
            return AnyPattern([self] + anyPattern.patterns)
        } else {
            return AnyPattern([self, pattern])
        }
    }
    
    func concat(_ pattern: PatternBase<S>)->SequencePattern<S> {
        if let seqPattern = pattern as? SequencePattern<S> {
            return SequencePattern(patterns: [self] + seqPattern.patterns)
        } else {
            return SequencePattern(self, pattern)
        }
    }
    
    func match(_ parser: ParserBase<S>) -> [SyntaxMatch<S>] {
        fatalError("Abstract method \(#function) not implemented")
    }
    
    open var opt: OptPattern<S> {
        return OptPattern(pattern: self)
    }
}

open class OptPattern<S: ParsingStateType>: PatternBase<S> {
    var basePattern: PatternBase<S>
    init(pattern: PatternBase<S>) {
        self.basePattern = pattern
        super.init("(\(pattern)).opt")
    }
    
    override func match(_ parser: ParserBase<S>) -> [SyntaxMatch<S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<S>] = []
        result += parser.matches(for: basePattern)
        result.append(SyntaxMatch(pattern: self, nodes: [], state: savedState))
        parser.state = savedState
        return result
    }
}

open class AnyPattern<S: ParsingStateType>: PatternBase<S> {
    var patterns: [PatternBase<S>]
    init(_ patterns: [PatternBase<S>]) {
        self.patterns = patterns
        super.init("(\(patterns.map{$0.string}.joined(separator: " | ")))")
    }
    override func or(_ pattern: PatternBase<S>)->AnyPattern<S> {
        if let anyPattern = pattern as? AnyPattern<S> {
            return AnyPattern(self.patterns + anyPattern.patterns)
        } else {
            return AnyPattern(self.patterns + [pattern])
        }
    }
    
    override func match(_ parser: ParserBase<S>) -> [SyntaxMatch<S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<S>] = []
        for pattern in patterns {
            result += parser.matches(for: pattern)
            parser.state = savedState
        }
        return result
    }
}

open class FailPattern<S: ParsingStateType>: PatternBase<S> {
    public override init() {
        super.init("_fail_")
    }
    
    override func match(_ parser: ParserBase<S>) -> [SyntaxMatch<S>] {
        return []
    }
}

open class NonTerminalBase<S: ParsingStateType>: PatternBase<S> {
    public typealias NodeConstructorType = (SyntaxMatch<S>) -> NodeBase
    
    open var nodeConstructor: NodeConstructorType?
    ///
    var pattern: PatternBase<S>? = nil
    
    public init(nodeConstructor: @escaping NodeConstructorType) {
        self.nodeConstructor = nodeConstructor
        super.init("_nt_")
    }
    
    public init(_ name: String, nodeConstructor: @escaping NodeConstructorType) {
        self.nodeConstructor = nodeConstructor
        super.init(name)
    }
    
    public override init(_ name: String) {
        super.init(name)
    }
    
    func addPattern(_ pattern: PatternBase<S>) {
        self.pattern = self.pattern?.or(pattern) ?? pattern
    }
    
    override func match(_ parser: ParserBase<S>) -> [SyntaxMatch<S>] {
        guard let pattern = self.pattern else {fatalError("match called before definition")}
        if nodeConstructor == nil {nodeConstructor = DefaultNodeConstructor}
        let matches = parser.matches(for: pattern)
        return matches.map {match in
            let nodes = [nodeConstructor!(match)]
            let state = match.state
            return SyntaxMatch(pattern: self, nodes: nodes, state: state)
        }
    }
}
///Intended to use while Syntax debugging
class PlainNode<S: ParsingStateType>: NodeBase {
    let match: SyntaxMatch<S>
    init(match: SyntaxMatch<S>) {
        self.match = match
    }
}
///Intended to use while Syntax debugging
func DefaultNodeConstructor<S>(_ match: SyntaxMatch<S>) -> NodeBase {
    return PlainNode(match: match)
}

open class TerminalBase<S: ParsingStateType>: PatternBase<S> {
    open var type: Token.Type? = nil
    var predicate: (String)->Bool
    
    public init(_ type: Token.Type) {
        self.type = type
        self.predicate = {_ in true}
        super.init(String(describing: type))
    }
    public init(type: Token.Type, _ predicate: @escaping (String)->Bool) {
        self.type = type
        self.predicate = predicate
        super.init(String(describing: type))
    }
    public convenience init(type: Token.Type, _ names: String...) {
        let nameSet = Set(names)
        self.init(type: type) {nameSet.contains($0)}
    }
    
    override open func match(_ parser: ParserBase<S>) -> [SyntaxMatch<S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<S>] = []
        do {
            let token = try parser.tokenizer.getToken(parser.state.context)
            //print("matching \(token.string.debugDescription) to \(self.type!)")
            if Swift.type(of: token) == self.type {
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

open class Symbol<S: ParsingStateType>: PatternBase<S>, ExpressibleByStringLiteral {
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
    
    override func match(_ parser: ParserBase<S>) -> [SyntaxMatch<S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<S>] = []
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

open class AnySymbol<S: ParsingStateType>: PatternBase<S> {
    var strings: Set<String>
    
    public init(_ strings: String...) {
        assert(strings.count > 0)
        self.strings = Set(strings)
        super.init(strings.first!)
    }
    
    override func match(_ parser: ParserBase<S>) -> [SyntaxMatch<S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<S>] = []
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

open class SetState<S: ParsingStateType>:  PatternBase<S> {
    
    var context: S.ContextType
    public init(_ context: S.ContextType) {
        self.context = context
        super.init(String(describing: context))
    }
    
    override func match(_ parser: ParserBase<S>) -> [SyntaxMatch<S>] {
        parser.state.context = self.context
        let result: [SyntaxMatch<S>] = [SyntaxMatch(pattern: self, nodes: [], state: parser.state)]
        return result
    }
}
open class PushAndSetState<S: StackableParsingState>:  PatternBase<S> {
    var context: S.ContextType
    var extraInfo: S.ExtraInfoType?
    public init(_ context: S.ContextType) {
        self.context = context
        super.init(String(describing: context))
    }
    public init(_ context: S.ContextType, extraInfo: S.ExtraInfoType) {
        self.context = context
        self.extraInfo = extraInfo
        super.init(String(describing: context))
    }
    
    override func match(_ parser: ParserBase<S>) -> [SyntaxMatch<S>] {
        parser.state.pushAndSet(self.context, newExtraInfo: self.extraInfo)
        let result: [SyntaxMatch<S>] = [SyntaxMatch(pattern: self, nodes: [], state: parser.state)]
        return result
    }
}
open class PopState<S: StackableParsingState>:  PatternBase<S> {
    public override init() {
        super.init("PopState")
    }
    
    override func match(_ parser: ParserBase<S>) -> [SyntaxMatch<S>] {
        parser.state.pop()
        let result: [SyntaxMatch<S>] = [SyntaxMatch(pattern: self, nodes: [], state: parser.state)]
        return result
    }
}

open class SequencePattern<S: ParsingStateType>: PatternBase<S> {
    
    var patterns: [PatternBase<S>]
    
    init(patterns: [PatternBase<S>]) {
        self.patterns = patterns
        super.init("("+patterns.map{$0.string}.joined(separator: " & ")+")")
    }
    
    public convenience init(_ patterns: PatternBase<S>...) {
        self.init(patterns: patterns)
    }
    
    override func concat(_ pattern: PatternBase<S>)->SequencePattern<S> {
        if let seqPattern = pattern as? SequencePattern {
            return SequencePattern(patterns: self.patterns + seqPattern.patterns)
        } else {
            return SequencePattern(patterns: self.patterns + [pattern])
        }
    }

    override func match(_ parser: ParserBase<S>) -> [SyntaxMatch<S>] {
        let savedState = parser.state
        var result: [SyntaxMatch<S>] = [SyntaxMatch(pattern: self, nodes: [], state: savedState)]
        for pattern in patterns {
            var updatedResult: [SyntaxMatch<S>] = []
            for match in result {
                parser.state = match.state
                let nextMatches = parser.matches(for: pattern)
                for nextMatch in nextMatches {
                    let nodes = match.nodes + nextMatch.nodes
                    let state = nextMatch.state
                    updatedResult.append(SyntaxMatch(pattern: self, nodes: nodes, state: state))
                }
            }
            result = updatedResult
            if result.isEmpty {
                break
            }
        }
        parser.state = savedState
        if result.count == 1 && result[0].nodes.count == 0 {
            return []
        }
        return result
    }
}

open class RepeatPattern<S: ParsingStateType>: PatternBase<S> {
    var pattern: PatternBase<S>
    var minCount: Int = 0
    init(_ pattern: PatternBase<S>) {
        self.pattern = pattern
        super.init("(\(pattern.string))"+(minCount==0 ? "*" : "+"))
    }
    init(_ pattern: PatternBase<S>, minCount: Int) {
        self.pattern = pattern
        self.minCount = minCount
        super.init("(\(pattern.string))"+(minCount==0 ? "*" : "+"))
    }

    override func match(_ parser: ParserBase<S>) -> [SyntaxMatch<S>] {
        let savedState = parser.state
        var lastMatches: [SyntaxMatch<S>] = [SyntaxMatch(pattern: self, nodes: [], state: savedState)]
        var result: [SyntaxMatch<S>] = []
        var i = 0
        outer: while true {
            if i >= minCount {
                result += lastMatches
            }
            var updatedResult: [SyntaxMatch<S>] = []
            for lastMatch in lastMatches {
                parser.state = lastMatch.state
                let nextMatches = parser.matches(for: pattern)
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
            
            i += 1
        }
        parser.state = savedState
        return result
    }
}

///Non-backtracking locally maximum-length repeat
open class LocalMaximumRepeatPattern<S: ParsingStateType>: RepeatPattern<S> {
    override init(_ pattern: PatternBase<S>) {
        super.init(pattern)
        self.string += "->"
    }
    override init(_ pattern: PatternBase<S>, minCount: Int) {
        super.init(pattern, minCount: minCount)
        self.string += "->"
    }
    
    override func match(_ parser: ParserBase<S>) -> [SyntaxMatch<S>] {
        let savedState = parser.state
        var lastMatches: [SyntaxMatch<S>] = [SyntaxMatch(pattern: self, nodes: [], state: savedState)]
        var result: [SyntaxMatch<S>] = []
        var i = 0
        outer: while true {
            if i >= minCount {
                result = lastMatches
            }
            var updatedResult: [SyntaxMatch<S>] = []
            for lastMatch in lastMatches {
                parser.state = lastMatch.state
                let nextMatches = parser.matches(for: pattern)
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
            
            i += 1
        }
        parser.state = savedState
        return result
    }
}

//infix operator ==> {precedence 90}
infix operator ==> :AssignmentPrecedence

//infix operator |=> {precedence 90}
infix operator |=> :AssignmentPrecedence

postfix operator +
postfix operator +->
postfix operator *
postfix operator *->

extension PatternBase {
    static public func ==> (lhs: NonTerminalBase<S>, rhs: PatternBase<S>) {
            lhs.pattern = rhs
    }
    
    static public func |=> (lhs: NonTerminalBase<S>, rhs: PatternBase<S>) {
            lhs.addPattern(rhs)
    }
    static public func | (lhs: PatternBase<S>, rhs: PatternBase<S>)->AnyPattern<S> {
            return lhs.or(rhs)
    }
    
    static public func & (lhs: PatternBase<S>, rhs: Symbol<S>)->SequencePattern<S> {
            return lhs.concat(rhs)
    }
    static public func & (lhs: Symbol<S>, rhs: PatternBase<S>)->SequencePattern<S> {
            return lhs.concat(rhs)
    }
    static public func & (lhs: PatternBase<S>, rhs: PatternBase<S>)->SequencePattern<S> {
            return lhs.concat(rhs)
    }
    
    static public postfix func + (pattern: PatternBase<S>) -> RepeatPattern<S> {
            return RepeatPattern(pattern, minCount: 1)
    }
    
    static public postfix func * (pattern: PatternBase<S>) -> RepeatPattern<S> {
            return RepeatPattern(pattern)
    }
    
    static public postfix func +-> (pattern: PatternBase<S>) -> LocalMaximumRepeatPattern<S> {
            return LocalMaximumRepeatPattern(pattern, minCount: 1)
    }
    
    static public postfix func *-> (pattern: PatternBase<S>) -> LocalMaximumRepeatPattern<S> {
            return LocalMaximumRepeatPattern(pattern)
    }
}

extension Symbol {
    static public func & (lhs: Symbol<S>, rhs: Symbol<S>)->SequencePattern<S> {
            return lhs.concat(rhs)
    }
}

public protocol ParsingStateType {
    associatedtype ContextType: LexicalContextType
    var context: ContextType {get set}
    init()
}
public protocol StackableParsingState: ParsingStateType {
    ///Extra information type saved in stack with ContextType
    associatedtype ExtraInfoType
    mutating func pushAndSet(_ newContext: ContextType)
    ///Use default if newExtraInfo == nil
    mutating func pushAndSet(_ newContext: ContextType, newExtraInfo: ExtraInfoType?)
    mutating func pop()
}
open class ParserBase<S: ParsingStateType> {
    
    open var tokenizer: TokenizerBase<S.ContextType>
    open var state: S = S()
    
    ///Debuggin: report matches
    open var shouldReportMatches: Bool = false
    ///Debuggin: report tests
    open var shouldReportTests: Bool = false
    
    open func setup() {
        fatalError("Abstract method \(#function) not implemented")
    }
    
    public init(tokenizer: TokenizerBase<S.ContextType>) {
        self.tokenizer = tokenizer
        tokenizer.reset()
        self.setup()
        //TODO: current parsing is too slow, needs compilation & optimization here...
    }
    
    open func reset() {
        tokenizer.reset()
        state = S()
    }
    
    open func parse(_ nt: NonTerminalBase<S>) -> NodeBase? {
        assert(nt.pattern != nil && nt.nodeConstructor != nil)
        let matches = self.matches(for: nt.pattern!)
        if matches.count > 0 {
            //First match only, as for now
            return nt.nodeConstructor!(matches.first!)
        } else {
            return nil
        }
    }
    
    open func matches(for pattern: PatternBase<S>) -> [SyntaxMatch<S>] {
        if shouldReportTests {
            print("Start: \(pattern.string)")
        }
        let result = pattern.match(self)
        if (shouldReportMatches || shouldReportTests) && !result.isEmpty {
            print("Found: \(pattern.string) found matches[\(result.count)]")
        }
        if shouldReportTests {
            if result.isEmpty {
                print("Fail : \(pattern.string)")
            }
            print("End  : \(pattern.string)")
        }
        return result
    }
}
