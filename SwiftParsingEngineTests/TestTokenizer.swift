//
//  Tokenizer.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/19.
//  Copyright © 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation
import SwiftParsingEngine
/*
[1] `simple-expression
[2] `(expression)
[3] `{statement}
[6] `for ... {...}
[8] `if ... {...}
[12]`<* ... *>
[13]`// ...
[14]`:
[15]``
*/
class HTMLTextToken: Token {}

class NilToken: Token {}
class TrueToken: Token {}
class FalseToken: Token {}

class IdentifierToken: Token {
    class func createInstance(string: String, _ range: NSRange) -> Token {
        switch string {
        case "if":
            return IfToken(string, range)
        case "for":
            return ForToken(string, range)
        case "in":
            return InToken(string, range)
        case "nil":
            return NilToken(string, range)
        case "true":
            return TrueToken(string, range)
        case "false":
            return FalseToken(string, range)
        default:
            if string.hasPrefix("`") && string.hasSuffix("`") {
                let nameRange = string.startIndex.successor()..<string.endIndex.predecessor()
                return IdentifierToken(string.substringWithRange(nameRange), range)
            }
            return IdentifierToken(string, range)
        }
    }
    
}

class QToken: Token {}
class DotToken: Token {}
class OperatorToken: Token {
    class func createInstance(string: String, _ range: NSRange) -> Token {
        switch string {
        case "?":
            return QToken(string, range)
        case ".":
            return DotToken(string, range)
        default:
            return OperatorToken(string, range)
        }
    }
    
}

class LeftParenthesis: Token {}
class RightParenthesis: Token {}

class LeftBrace: Token {}
class RightBrace: Token {}

class LeftBracket: Token {}
class RightBracket: Token {}

class ForToken: Token {}
class InToken: Token {}
class IfToken: Token {}

class CommentStart: Token {}
class CommentEnd: Token {}

class InlineLeader: Token {}
class LineEscape: Token {}
class TagEscape: Token {}

class TagOpener: Token {
    var tagName: String {
        //remove "<"
        return string.substringFromIndex(string.startIndex.successor())
    }
}
class ClosingTag: Token {
    var tagName: String {
        //remove "</"
        return string.substringFromIndex(string.startIndex.advancedBy(2))
    }
}

class NewLine: Token {}
class WhiteSpace: Token {}

class IntegerToken: Token {}
class FloatingPointToken: Token {}
class StringToken: Token {}

class SymbolToken: Token {}

class InvalidToken: Token {}

struct LexicalContext: LexicalContextType {
    private(set) var rawValue: Int
    init(rawValue: Int) {self.rawValue = rawValue}
    
    static let HTML = LexicalContext(rawValue: 1<<0)  //Initial state: leads arbitrary HTML text
    static let Inline = LexicalContext(rawValue: 1<<1) //Leaded by {:, contains HTML text except }
    static let LineEscape = LexicalContext(rawValue: 1<<2) //Leaded by `: contains HTML text except NewLine
    static let InsideTag = LexicalContext(rawValue: 1<<3)
    static let TagEscape = LexicalContext(rawValue: 1<<4) //Leaded by opening tag, terminated by corresponding closing tag
    
    static let Simple = LexicalContext(rawValue: 1<<5)
    static let Expression = LexicalContext(rawValue: 1<<6)
    static let Block = LexicalContext(rawValue: 1<<7)
    
    static let Comment = LexicalContext(rawValue: 1<<8)
    
    static let Initial: LexicalContext = .HTML
}
extension LexicalContext: Hashable {
    var hashValue: Int {return rawValue}
}
let TAG_NAME = "[_:\\p{L}][-._:\\p{L}\\p{Nd}\\p{Mn}]*"
let OP_CHARS = "[-/=+!*%<>&|^?~]"
class Tokenizer: TokenizerBase<LexicalContext> {
    override init(string: String?) {
        super.init(string: string)
    }
    
    private static var _matchers: [TM] = {
        let templates: [(String, LexicalContext, TM.TokenizingProc)] = [
            ("((?:[^`]|``)+)", .HTML, {HTMLTextToken($0)}),
            ("((?:[^`*]|``|\\*[^>])+)", .Comment, {HTMLTextToken($0)}),
            ("((?:[^`\r\n\\}]|``)+)", .Inline, {HTMLTextToken($0)}),
            ("((?:[^`\r\n]|``)+)", .LineEscape, {HTMLTextToken($0)}),
            ("((?:[^`<]|``|<[^/_:\\p{L}]|</[^_:\\p{L}])+)", .TagEscape, {HTMLTextToken($0)}),
            ("((?:[^`<>]|``)+)", .InsideTag, {HTMLTextToken($0)}),
            
//            ("(<text)\\s*>", [.Block,.Expression], {TagOpener($0)}),
            ("(<"+TAG_NAME+")", [.TagEscape,.Block,.Expression], {TagOpener($0)}),
            ("(</"+TAG_NAME+")\\s*>", .TagEscape, {ClosingTag($0)}),
            ("(<)", .InsideTag, {InvalidToken($0)}),
            ("(>)", .InsideTag, {SymbolToken($0)}),
            ("(/>)", .InsideTag, {SymbolToken($0)}),
            
            ("`([_a-zA-Z][_a-zA-Z0-9]*)", [.HTML,.Inline,.LineEscape,.TagEscape,.InsideTag], {IdentifierToken.createInstance($0)}),
            ("`(\\$[0-9]+)", [.HTML,.Inline,.LineEscape,.TagEscape,.InsideTag], {IdentifierToken.createInstance($0)}),
            
            ("([_\\p{L}][_\\p{L}\\p{Nd}\\p{Mn}]*)", [.Expression,.Block], {IdentifierToken.createInstance($0)}),
            ("([_a-zA-Z][_a-zA-Z0-9]*)", .Simple, {IdentifierToken.createInstance($0)}),
            ("([0-9]+)", .Simple, {IntegerToken($0)}),
            ("([^0-9_a-zA-Z\\.\\{\\[\\(])", .Simple, {InvalidToken($0)}),
            
            ("`(<\\*)", [.HTML,.Comment,.Inline,.LineEscape,.TagEscape,.InsideTag], {CommentStart($0)}),
            ("(\\*>)", [.Comment], {CommentEnd($0)}),
            
            ("`(\\()", [.HTML,.Comment,.Inline,.LineEscape,.TagEscape,.InsideTag], {LeftParenthesis($0)}),
            ("(\\()", [.Expression,.Simple,.Block], {LeftParenthesis($0)}),
            ("(\\))", [.Expression,.Block], {RightParenthesis($0)}),
            ("`(\\{)", [.HTML,.Comment,.Inline,.LineEscape,.TagEscape,.InsideTag], {LeftBrace($0)}),
            ("(\\{:)", [.Expression,.Block], {InlineLeader($0)}),
            ("(\\{)", [.Expression,.Simple,.Block], {LeftBrace($0)}),
            ("(\\})", [.Expression,.Block,.Inline], {RightBrace($0)}),
            ("(\\[)", [.Expression,.Simple,.Block], {LeftBracket($0)}),
            ("(\\])", [.Expression,.Block], {RightBracket($0)}),
            
            ("([0-9][0-9_]*(?:\\.[0-9][0-9_]*)(?:[eE][-+]?[0-9][0-9_]*)|" +
                "0x[0-9a-fA-F][0-9a-fA-F_]*(?:\\.[0-9a-fA-F][0-9a-fA-F_]*)(?:[pP][-+]?[0-9][0-9_]*))",
                [.Expression,.Block], {FloatingPointToken($0)}),
            ("(0b[01][01_]*|0o[0-7][0-7_]*|[0-9][0-9_]*|0x[0-9a-fA-F][0-9a-fA-F_]*)",
                [.Expression,.Block], {IntegerToken($0)}),
            ("(\"(?:[^\"\\\\]|\\\\(?:[0\\\\tnr\"']|u\\{[0-9a-fA-F]{1,8}\\}))*\")",
                [.Expression,.Block], {StringToken($0)}),
            
            ("(`:)", [.HTML,.Inline,.LineEscape,.TagEscape,/*.Simple,*/.InsideTag], {LineEscape($0)}),
            
            ("`//.*((?:\r\n|\r|\n|$))", [.HTML,.TagEscape,/*.Simple,*/.InsideTag], {NewLine($0)}),
//            ("([^`_a-zA-Z\\.\\{\\[\\(](?:[^`\r\n\\}<]|``)+)", .Simple, {HTMLTextToken($0)}),
            ("(?://.*)?((?:\r\n|\r|\n|$))", [.Expression,.Block], {NewLine($0)}),
            ("([\t \\p{Z}]+)", [.Expression,.Block], {WhiteSpace($0)}),
            
            ("(\\.+)", [.Expression,.Block,.Simple], {OperatorToken.createInstance($0)}),
            ("("+OP_CHARS+"+)", [.Expression,.Block], {OperatorToken.createInstance($0)}),
        ]
        return templates.map(TM.init)
    }()
    override var matchers: [TM] {
        return Tokenizer._matchers
    }
}
