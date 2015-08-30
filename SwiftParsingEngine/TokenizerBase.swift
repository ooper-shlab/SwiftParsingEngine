//
//  TokenizerBase.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/19.
//  Copyright © 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation

class InternedString {
    private static var internDictionary: [String: InternedString] = [:]
    let string: String
    private init(string: String) {
        self.string = string
    }
    
    class func intern(string: String) -> InternedString {
        if let result = internDictionary[string] {
            return result
        } else {
            return InternedString(string: string)
        }
    }
}
public class TokenBase {
    public var string: String
    ///position in UTF-16 in source
    var position: Int
//    class func createToken(string: String) -> TokenBase {
//        fatalError("Abstract method \(__FUNCTION__) not implemented")
//    }
    public class func getEndToken(position: Int) -> Self {
        fatalError("Abstract method \(__FUNCTION__) not implemented")
    }
    
    public init(_ string: String, _ position: Int) {
        self.string = string
        self.position = position
    }
}

public protocol StateType: OptionSetType {
    static var Initial: Self {get}
//    static var AllStates: [Self] {get}
}
public class TokenMatcher<S: StateType, T: TokenBase where S.Element == S> {
    
    public typealias TokenizingProc = (String, Int)->T
    
    var regex: NSRegularExpression
    var state: S
    var proc: TokenizingProc
    public init(_ pattern: String, _ state: S, _ proc: TokenizingProc) {
        self.regex = try! NSRegularExpression(pattern: "^" + pattern, options: [])
        self.state = state
        self.proc = proc
    }
}
public enum TokenizerError: ErrorType {
    case NoMatchingPattern(String)
}
public class TokenizerBase<S: StateType, T: TokenBase where S.Element == S> {
    
    public var currentState: S = .Initial
    ///position in UTF-16
    var currentPosition: Int = 0
    var parsingState: (S, Int) {
        get {return (currentState, currentPosition)}
        set {(currentState, currentPosition) = newValue}
    }
    
    private var string: String
    private var matchers: [TokenMatcher<S,T>] = []
    
    public init(string: String, syntax: [TokenMatcher<S,T>]) {
        self.string = string
        self.matchers = syntax
        //super.init()
    }
    
    public func getToken() throws -> T {
        let range = NSRange(currentPosition..<string.utf16.count)
        if range.length == 0 {
            return T.getEndToken(range.location)
        }
        for matcher in matchers
        where matcher.state.contains(currentState) {
            //print("--"+matcher.regex.pattern.debugDescription)
            if let match = matcher.regex.firstMatchInString(string, options: [], range: range) {
                let range = match.numberOfRanges == 1 ? match.range : match.rangeAtIndex(1)
                let substring = (string as NSString).substringWithRange(range)
                let token = matcher.proc(substring, currentPosition)
                currentPosition += match.range.length
                return token
            }
        }
        let head = (string as NSString).substringWithRange(NSRange(currentPosition..<currentPosition+5))
        throw TokenizerError.NoMatchingPattern("No matches in current state: \(currentState.rawValue) for \(head.debugDescription)")
    }

}
