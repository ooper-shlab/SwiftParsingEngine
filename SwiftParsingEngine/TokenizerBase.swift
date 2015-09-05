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
            let result = InternedString(string: string)
            internDictionary[string] = result
            return result
        }
    }
}

public class Token {
    public var string: String
    ///range in UTF-16 in source
    var range: NSRange
    
    public init(_ string: String, _ range: NSRange) {
        self.range = range
        self.string = string
    }
    public init(_ string: String) {
        self.string = string
        self.range = NSRange()
    }
    public init() {
        self.string = ""
        self.range = NSRange()
    }
}

public class EndToken: Token {}


public protocol LexicalContextType: OptionSetType {
    static var Initial: Self {get}
}

public class TokenMatcher<C: LexicalContextType where C.Element == C> {
    
    public typealias TokenizingProc = (String, NSRange)->Token
    
    var regex: NSRegularExpression
    var context: C
    var proc: TokenizingProc
    public init(_ pattern: String, _ context: C, _ proc: TokenizingProc) {
        self.regex = try! NSRegularExpression(pattern: "^" + pattern, options: [])
        self.context = context
        self.proc = proc
    }
}
public enum TokenizerError: ErrorType {
    case NoMatchingPattern(String)
}
public class TokenizerBase<C: LexicalContextType where C.Element == C, C: Hashable> {
    
    public var currentContext: C = .Initial
    ///position in UTF-16
    public var currentPosition: Int = 0
    
    private var string: String
    public typealias TM = TokenMatcher<C>
    public var matchers: [TM] {
        fatalError("Abstract method \(__FUNCTION__) not implemented")
    }
    
    public init(string: String?) {
        self.string = string ?? ""
    }
    
    public func reset(string: String) {
        self.string = string
        currentContext = .Initial
        currentPosition = 0
    }
    
    var cachedToken: [C: [Int: Token]] = [:]
    public func getToken() throws -> Token {
        if let cache = cachedToken[currentContext] {
            if let token = cache[currentPosition] {
                //print("(cache)-->"+token.string.debugDescription)
                currentPosition += token.range.length
                return token
            }
        } else {
            cachedToken[currentContext] = [:]
        }
        let range = NSRange(currentPosition..<string.utf16.count)
        if range.length == 0 {
            return EndToken("", range)
        }
        for matcher in matchers
        where matcher.context.contains(currentContext) {
            //print("--"+matcher.regex.pattern.debugDescription)
            if let match = matcher.regex.firstMatchInString(string, options: [], range: range) {
                let range = match.numberOfRanges == 1 ? match.range : match.rangeAtIndex(1)
                let substring = (string as NSString).substringWithRange(range)
                let token = matcher.proc(substring, match.range)
                cachedToken[currentContext]![currentPosition] = token //###
                currentPosition += match.range.length
                return token
            }
        }
        let head = (string as NSString).substringWithRange(NSRange(currentPosition..<currentPosition+5))
        throw TokenizerError.NoMatchingPattern("No matches in current state: \(currentContext.rawValue) for \(head.debugDescription)")
    }

}
