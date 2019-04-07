//
//  Tokenizer.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/19.
//  Copyright © 2015-2017 OOPer (NAGATA, Atsuyuki). All rights reserved.
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
    class func createInstance(_ string: String, _ range: NSRange) -> Token {
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
                return IdentifierToken(String(string.dropFirst().dropLast()), range)
            }
            return IdentifierToken(string, range)
        }
    }
    
}

class QToken: Token {}
class DotToken: Token {}
class OperatorToken: Token {
    class func createInstance(_ string: String, _ range: NSRange) -> Token {
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
        return String(string.dropFirst())
    }
}
class ClosingTag: Token {
    var tagName: String {
        //remove "</"
        return String(string.dropFirst(2))
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
    fileprivate(set) var rawValue: Int
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
    
    fileprivate static var _matchers: [TM] = {
        let templates: [(String, LexicalContext, TM.TokenizingProc)] = [
            ("((?:[^`]|``)+)", .HTML, {s,r in HTMLTextToken(s,r)}),
            ("((?:[^`*]|``|\\*[^>])+)", .Comment, {s,r in HTMLTextToken(s,r)}),
            ("((?:[^`\r\n\\}]|``)+)", .Inline, {s,r in HTMLTextToken(s,r)}),
            ("((?:[^`\r\n]|``)+)", .LineEscape, {s,r in HTMLTextToken(s,r)}),
            ("((?:[^`<]|``|<[^/_:\\p{L}]|</[^_:\\p{L}])+)", .TagEscape, {s,r in HTMLTextToken(s,r)}),
            ("((?:[^`<>]|``)+)", .InsideTag, {s,r in HTMLTextToken(s,r)}),
            
//            ("(<text)\\s*>", [.Block,.Expression], {TagOpener($0)}),
            ("(<"+TAG_NAME+")", [.TagEscape,.Block,.Expression], {s,r in TagOpener(s,r)}),
            ("(</"+TAG_NAME+")\\s*>", .TagEscape, {s,r in ClosingTag(s,r)}),
            ("(<)", .InsideTag, {s,r in InvalidToken(s,r)}),
            ("(>)", .InsideTag, {s,r in SymbolToken(s,r)}),
            ("(/>)", .InsideTag, {s,r in SymbolToken(s,r)}),
            
            ("`([_a-zA-Z][_a-zA-Z0-9]*)", [.HTML,.Inline,.LineEscape,.TagEscape,.InsideTag], {s,r in IdentifierToken.createInstance(s,r)}),
            ("`(\\$[0-9]+)", [.HTML,.Inline,.LineEscape,.TagEscape,.InsideTag], {s,r in IdentifierToken.createInstance(s,r)}),
            
            ("([_\\p{L}][_\\p{L}\\p{Nd}\\p{Mn}]*)", [.Expression,.Block], {s,r in IdentifierToken.createInstance(s,r)}),
            ("([_a-zA-Z][_a-zA-Z0-9]*)", .Simple, {s,r in IdentifierToken.createInstance(s,r)}),
            ("([0-9]+)", .Simple, {s,r in IntegerToken(s,r)}),
            ("([^0-9_a-zA-Z\\.\\{\\[\\(])", .Simple, {s,r in InvalidToken(s,r)}),
            
            ("`(<\\*)", [.HTML,.Comment,.Inline,.LineEscape,.TagEscape,.InsideTag], {s,r in CommentStart(s,r)}),
            ("(\\*>)", [.Comment], {s,r in CommentEnd(s,r)}),
            
            ("`(\\()", [.HTML,.Comment,.Inline,.LineEscape,.TagEscape,.InsideTag], {s,r in LeftParenthesis(s,r)}),
            ("(\\()", [.Expression,.Simple,.Block], {s,r in LeftParenthesis(s,r)}),
            ("(\\))", [.Expression,.Block], {s,r in RightParenthesis(s,r)}),
            ("`(\\{)", [.HTML,.Comment,.Inline,.LineEscape,.TagEscape,.InsideTag], {s,r in LeftBrace(s,r)}),
            ("(\\{:)", [.Expression,.Block], {s,r in InlineLeader(s,r)}),
            ("(\\{)", [.Expression,.Simple,.Block], {s,r in LeftBrace(s,r)}),
            ("(\\})", [.Expression,.Block,.Inline], {s,r in RightBrace(s,r)}),
            ("(\\[)", [.Expression,.Simple,.Block], {s,r in LeftBracket(s,r)}),
            ("(\\])", [.Expression,.Block], {s,r in RightBracket(s,r)}),
            
            ("([0-9][0-9_]*(?:\\.[0-9][0-9_]*)(?:[eE][-+]?[0-9][0-9_]*)|" +
                "0x[0-9a-fA-F][0-9a-fA-F_]*(?:\\.[0-9a-fA-F][0-9a-fA-F_]*)(?:[pP][-+]?[0-9][0-9_]*))",
                [.Expression,.Block], {s,r in FloatingPointToken(s,r)}),
            ("(0b[01][01_]*|0o[0-7][0-7_]*|[0-9][0-9_]*|0x[0-9a-fA-F][0-9a-fA-F_]*)",
                [.Expression,.Block], {s,r in IntegerToken(s,r)}),
            ("(\"(?:[^\"\\\\]|\\\\(?:[0\\\\tnr\"']|u\\{[0-9a-fA-F]{1,8}\\}))*\")",
                [.Expression,.Block], {s,r in StringToken(s,r)}),
            
            ("(`:)", [.HTML,.Inline,.LineEscape,.TagEscape,/*.Simple,*/.InsideTag], {s,r in LineEscape(s,r)}),
            
            ("`//.*((?:\r\n|\r|\n|$))", [.HTML,.TagEscape,/*.Simple,*/.InsideTag], {s,r in NewLine(s,r)}),
//            ("([^`_a-zA-Z\\.\\{\\[\\(](?:[^`\r\n\\}<]|``)+)", .Simple, {HTMLTextToken($0)}),
            ("(?://.*)?((?:\r\n|\r|\n|$))", [.Expression,.Block], {s,r in NewLine(s,r)}),
            ("([\t \\p{Z}]+)", [.Expression,.Block], {s,r in WhiteSpace(s,r)}),
            
            ("(\\.+)", [.Expression,.Block,.Simple], {s,r in OperatorToken.createInstance(s,r)}),
            ("("+OP_CHARS+"+)", [.Expression,.Block], {s,r in OperatorToken.createInstance(s,r)}),
        ]
        return templates.map(TM.init)
    }()
    override var matchers: [TM] {
        return Tokenizer._matchers
    }
}
