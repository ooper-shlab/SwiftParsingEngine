//
//  TokenizerBase.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/19.
//  Copyright © 2015-2017 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation

class InternedString {
    fileprivate static var internDictionary: [String: InternedString] = [:]
    let string: String
    fileprivate init(string: String) {
        self.string = string
    }
    
    class func intern(_ string: String) -> InternedString {
        if let result = internDictionary[string] {
            return result
        } else {
            let result = InternedString(string: string)
            internDictionary[string] = result
            return result
        }
    }
}

open class Token {
    open var string: String
    ///range in UTF-16 in source
    var range: NSRange
    
    public init(_ string: String, _ range: NSRange) {
        self.range = range
        self.string = string
    }
//    public init(_ string: String) {
//        self.string = string
//        self.range = NSRange()
//    }
//    public init() {
//        self.string = ""
//        self.range = NSRange()
//    }
}

open class EndToken: Token {}


public protocol LexicalContextType: OptionSet, Hashable where Element == Self {
    static var Initial: Self {get}
}

open class TokenMatcher<C: LexicalContextType> {
    
    public typealias TokenizingProc = (String, NSRange)->Token
    
    var regex: NSRegularExpression
    var context: C
    var proc: TokenizingProc
    public init(_ pattern: String, _ context: C, _ proc: @escaping TokenizingProc) {
        self.regex = try! NSRegularExpression(pattern: "^" + pattern, options: [])
        self.context = context
        self.proc = proc
    }
}
public enum TokenizerError: Error {
    case noMatchingPattern(String)
}
open class TokenizerBase<C: LexicalContextType> {
    
    ///position in UTF-16
    open var currentPosition: Int = 0
    
    fileprivate var string: String
    
    var cachedToken: [C: [Int: Token]] = [:]
    
    public typealias TM = TokenMatcher<C>
    open var matchers: [TM] {
        fatalError("Abstract method \(#function) not implemented")
    }
    
    public init(string: String?) {
        self.string = string ?? ""
    }
    
    open func reset(_ string: String) {
        self.string = string
        currentPosition = 0
        cachedToken = [:]
    }
    open func reset() {
        currentPosition = 0
    }
    
//    public func getToken() throws -> Token {
//        return try getToken(C.Initial)
//    }
    open func getToken(_ context: C) throws -> Token {
        if let cache = cachedToken[context] {
            if let token = cache[currentPosition] {
                //print("(cache)-->"+token.string.debugDescription)
                currentPosition += token.range.length
                return token
            }
        } else {
            cachedToken[context] = [:]
        }
        let range = NSRange(currentPosition..<string.utf16.count)
        if range.length == 0 {
            return EndToken("", range)
        }
        for matcher in matchers
        where matcher.context.contains(context) {
            //print("--"+matcher.regex.pattern.debugDescription)
            if let match = matcher.regex.firstMatch(in: string, options: [], range: range) {
                let range = match.numberOfRanges == 1 ? match.range : match.range(at: 1)
                let substring = (string as NSString).substring(with: range)
                let token = matcher.proc(substring, match.range)
                cachedToken[context]![currentPosition] = token //###
                currentPosition += match.range.length
                return token
            }
        }
        let head = (string as NSString).substring(with: NSRange(currentPosition..<currentPosition+5))
        throw TokenizerError.noMatchingPattern("No matches in current state: \(context) for \(head.debugDescription)")
    }

}
