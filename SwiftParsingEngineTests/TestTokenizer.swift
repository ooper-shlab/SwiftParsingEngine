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
class Token: TokenBase {
    override class func getEndToken(position: Int) -> Token {
        return EndToken("", position)
    }
}

class EndToken: Token {}

class HTMLTextToken: Token {}

class NilToken: Token {}
class TrueToken: Token {}
class FalseToken: Token {}

class IdentifierToken: Token {
    class func createInstance(string: String, _ position: Int) -> Token {
        switch string {
        case "if":
            return IfToken(string, position)
        case "for":
            return ForToken(string, position)
        case "in":
            return InToken(string, position)
        case "nil":
            return NilToken(string, position)
        case "true":
            return TrueToken(string, position)
        case "false":
            return FalseToken(string, position)
        default:
            if string.hasPrefix("`") && string.hasSuffix("`") {
                let range = string.startIndex.successor()..<string.endIndex.predecessor()
                return IdentifierToken(string.substringWithRange(range), position)
            }
            return IdentifierToken(string, position)
        }
    }
    
}

class QToken: Token {}
class DotToken: Token {}
class OperatorToken: Token {
    class func createInstance(string: String, _ position: Int) -> Token {
        switch string {
        case "?":
            return QToken(string, position)
        case ".":
            return DotToken(string, position)
        default:
            return OperatorToken(string, position)
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

class TagOpener: Token {}
class ClosingTag: Token {}

class NewLine: Token {}
class WhiteSpace: Token {}

struct LexicalState: StateType {
    private(set) var rawValue: Int
    init(rawValue: Int) {self.rawValue = rawValue}
    
    static let HTML = LexicalState(rawValue: 1<<0)  //Initial state: leads arbitrary HTML text
    static let Inline = LexicalState(rawValue: 1<<1) //Leaded by {:, contains HTML text except }
    static let LineEscape = LexicalState(rawValue: 1<<2) //Leaded by `: contains HTML text except NewLine
    static let TagEscape = LexicalState(rawValue: 1<<3) //Leaded by opening tag, terminated by corresponding closing tag
    
    static let Simple = LexicalState(rawValue: 1<<4)
    static let Expression = LexicalState(rawValue: 1<<5)
    static let Block = LexicalState(rawValue: 1<<6)
    
    static let Comment = LexicalState(rawValue: 1<<7)
    
    static let Initial: LexicalState = .HTML
}
typealias TM = TokenMatcher<LexicalState,Token>
let TAG_NAME = "[_:\\p{L}][-._:\\p{L}\\p{Nd}\\p{Mn}]*"
let OP_CHARS = "[-/=+!*%<>&|^?~]"
let lexicalSyntax: [TM] = [
    ("((?:[^`]|``)+)", .HTML, {HTMLTextToken($0)}),
    ("((?:[^`*]|``|\\*[^>])+)", .Comment, {HTMLTextToken($0)}),
    ("((?:[^`\r\n\\}]|``)+)", .Inline, {HTMLTextToken($0)}),
    ("((?:[^`\r\n]|``)+)", .LineEscape, {HTMLTextToken($0)}),
    ("((?:[^`<]|``|<[^/_:\\p{L}]|</[^_:\\p{L}])+)", .TagEscape, {HTMLTextToken($0)}),
    
    ("<(text)\\s*>", [.Block,.Expression], {TagOpener($0)}),
    ("<("+TAG_NAME+")", [.TagEscape,.Block,.Expression], {TagOpener($0)}),
    ("</("+TAG_NAME+")\\s*>", .TagEscape, {ClosingTag($0)}),
    
    ("`([_a-zA-Z][_a-zA-Z0-9]*)", [.HTML,.Inline,.LineEscape,.TagEscape], {IdentifierToken.createInstance($0)}),
    ("`(\\$[0-9]+)", [.HTML,.Inline,.LineEscape,.TagEscape], {IdentifierToken.createInstance($0)}),
    ("([_\\p{L}][_\\p{L}\\p{Nd}\\p{Mn}]*)", [.Expression,.Block], {IdentifierToken.createInstance($0)}),
    ("\\.([_a-zA-Z][_a-zA-Z0-9]*)", .Simple, {IdentifierToken.createInstance($0)}),
    ("\\.([0-9]+)", .Simple, {IdentifierToken.createInstance($0)}),
    
    ("`(<\\*)", [.HTML,.Comment,.Inline,.LineEscape,.TagEscape], {CommentStart($0)}),
    ("(\\*>)", [.Comment], {CommentEnd($0)}),
    
    ("`(\\()", [.HTML,.Comment,.Inline,.LineEscape,.TagEscape], {LeftParenthesis($0)}),
    ("(\\()", [.Expression,.Simple,.Block], {LeftParenthesis($0)}),
    ("(\\))", [.Expression,.Simple,.Block], {RightParenthesis($0)}),
    ("`(\\{)", [.HTML,.Comment,.Inline,.LineEscape,.TagEscape], {LeftBrace($0)}),
    ("(\\{:)", [.Expression,.Block], {InlineLeader($0)}),
    ("(\\{)", [.Expression,.Simple,.Block], {LeftBrace($0)}),
    ("(\\})", [.Expression,.Block,.Inline], {RightBrace($0)}),
    ("(\\[)", [.Expression,.Simple,.Block], {LeftBracket($0)}),
    ("(\\])", [.Expression,.Block], {RightBracket($0)}),
    
    ("(`:)", [.Block], {LineEscape($0)}),
    
    ("`(//.*(?:\r\n|\r|\n|$))", [.HTML,.TagEscape,.Simple], {NewLine($0)}),
    ("([^`_a-zA-Z\\.\\{\\[\\(](?:[^`\r\n\\}<]|``)+)", .Simple, {HTMLTextToken($0)}),
    ("((?://.*)?(?:\r\n|\r|\n|$))", [.Expression,.Block], {NewLine($0)}),
    ("([\t \\p{Z}]+)", [.Expression,.Block], {WhiteSpace($0)}),
    
    ("(\\.+)", [.Expression,.Block], {OperatorToken.createInstance($0)}),
    ("("+OP_CHARS+"+)", [.Expression,.Block], {OperatorToken.createInstance($0)}),
].map(TM.init)
class Tokenizer: TokenizerBase<LexicalState,Token> {
    override init(string: String, syntax: [TM]) {
        super.init(string: string, syntax: syntax)
    }
}
