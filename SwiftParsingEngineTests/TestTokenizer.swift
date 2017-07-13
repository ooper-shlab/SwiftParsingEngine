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
                let nameRange = string.characters.index(after: string.startIndex)..<string.characters.index(before: string.endIndex)
                return IdentifierToken(string.substring(with: nameRange), range)
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
        return string.substring(from: string.characters.index(after: string.startIndex))
    }
}
class ClosingTag: Token {
    var tagName: String {
        //remove "</"
        return string.substring(from: string.characters.index(string.startIndex, offsetBy: 2))
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
            ("((?:[^`]|``)+)", .HTML, {s,_ in HTMLTextToken(s)}),
            ("((?:[^`*]|``|\\*[^>])+)", .Comment, {s,_ in HTMLTextToken(s)}),
            ("((?:[^`\r\n\\}]|``)+)", .Inline, {s,_ in HTMLTextToken(s)}),
            ("((?:[^`\r\n]|``)+)", .LineEscape, {s,_ in HTMLTextToken(s)}),
            ("((?:[^`<]|``|<[^/_:\\p{L}]|</[^_:\\p{L}])+)", .TagEscape, {s,_ in HTMLTextToken(s)}),
            ("((?:[^`<>]|``)+)", .InsideTag, {s,_ in HTMLTextToken(s)}),
            
//            ("(<text)\\s*>", [.Block,.Expression], {TagOpener($0)}),
            ("(<"+TAG_NAME+")", [.TagEscape,.Block,.Expression], {s,_ in TagOpener(s)}),
            ("(</"+TAG_NAME+")\\s*>", .TagEscape, {s,_ in ClosingTag(s)}),
            ("(<)", .InsideTag, {s,_ in InvalidToken(s)}),
            ("(>)", .InsideTag, {s,_ in SymbolToken(s)}),
            ("(/>)", .InsideTag, {s,_ in SymbolToken(s)}),
            
            ("`([_a-zA-Z][_a-zA-Z0-9]*)", [.HTML,.Inline,.LineEscape,.TagEscape,.InsideTag], {s,r in IdentifierToken.createInstance(s,r)}),
            ("`(\\$[0-9]+)", [.HTML,.Inline,.LineEscape,.TagEscape,.InsideTag], {s,r in IdentifierToken.createInstance(s,r)}),
            
            ("([_\\p{L}][_\\p{L}\\p{Nd}\\p{Mn}]*)", [.Expression,.Block], {s,r in IdentifierToken.createInstance(s,r)}),
            ("([_a-zA-Z][_a-zA-Z0-9]*)", .Simple, {s,r in IdentifierToken.createInstance(s,r)}),
            ("([0-9]+)", .Simple, {s,_ in IntegerToken(s)}),
            ("([^0-9_a-zA-Z\\.\\{\\[\\(])", .Simple, {s,_ in InvalidToken(s)}),
            
            ("`(<\\*)", [.HTML,.Comment,.Inline,.LineEscape,.TagEscape,.InsideTag], {s,_ in CommentStart(s)}),
            ("(\\*>)", [.Comment], {s,_ in CommentEnd(s)}),
            
            ("`(\\()", [.HTML,.Comment,.Inline,.LineEscape,.TagEscape,.InsideTag], {s,_ in LeftParenthesis(s)}),
            ("(\\()", [.Expression,.Simple,.Block], {s,_ in LeftParenthesis(s)}),
            ("(\\))", [.Expression,.Block], {s,_ in RightParenthesis(s)}),
            ("`(\\{)", [.HTML,.Comment,.Inline,.LineEscape,.TagEscape,.InsideTag], {s,_ in LeftBrace(s)}),
            ("(\\{:)", [.Expression,.Block], {s,_ in InlineLeader(s)}),
            ("(\\{)", [.Expression,.Simple,.Block], {s,_ in LeftBrace(s)}),
            ("(\\})", [.Expression,.Block,.Inline], {s,_ in RightBrace(s)}),
            ("(\\[)", [.Expression,.Simple,.Block], {s,_ in LeftBracket(s)}),
            ("(\\])", [.Expression,.Block], {s,_ in RightBracket(s)}),
            
            ("([0-9][0-9_]*(?:\\.[0-9][0-9_]*)(?:[eE][-+]?[0-9][0-9_]*)|" +
                "0x[0-9a-fA-F][0-9a-fA-F_]*(?:\\.[0-9a-fA-F][0-9a-fA-F_]*)(?:[pP][-+]?[0-9][0-9_]*))",
                [.Expression,.Block], {s,_ in FloatingPointToken(s)}),
            ("(0b[01][01_]*|0o[0-7][0-7_]*|[0-9][0-9_]*|0x[0-9a-fA-F][0-9a-fA-F_]*)",
                [.Expression,.Block], {s,_ in IntegerToken(s)}),
            ("(\"(?:[^\"\\\\]|\\\\(?:[0\\\\tnr\"']|u\\{[0-9a-fA-F]{1,8}\\}))*\")",
                [.Expression,.Block], {s,_ in StringToken(s)}),
            
            ("(`:)", [.HTML,.Inline,.LineEscape,.TagEscape,/*.Simple,*/.InsideTag], {s,_ in LineEscape(s)}),
            
            ("`//.*((?:\r\n|\r|\n|$))", [.HTML,.TagEscape,/*.Simple,*/.InsideTag], {s,_ in NewLine(s)}),
//            ("([^`_a-zA-Z\\.\\{\\[\\(](?:[^`\r\n\\}<]|``)+)", .Simple, {HTMLTextToken($0)}),
            ("(?://.*)?((?:\r\n|\r|\n|$))", [.Expression,.Block], {s,_ in NewLine(s)}),
            ("([\t \\p{Z}]+)", [.Expression,.Block], {s,_ in WhiteSpace(s)}),
            
            ("(\\.+)", [.Expression,.Block,.Simple], {s,r in OperatorToken.createInstance(s,r)}),
            ("("+OP_CHARS+"+)", [.Expression,.Block], {s,r in OperatorToken.createInstance(s,r)}),
        ]
        return templates.map(TM.init)
    }()
    override var matchers: [TM] {
        return Tokenizer._matchers
    }
}
