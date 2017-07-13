//
//  SimpleTokenizer.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/9/1.
//  Copyright © 2015-2017 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation
import SwiftParsingEngine

/* ---------------------------------------------------------------------------------------- *
    [Tokenizer]

    In order to uitlize SwiftParsingEngine, you need to define three categories of types,
    tokenizer, parser and node. This file describes about definitions in Tokenizer category.

    In the tokenizer category, you declare three kinds of types.

    Type 1. Token classes
    Type 2. LecicalContext type
    Type 3. Tokenizer class

 * ---------------------------------------------------------------------------------------- */

//
//MARK: Type 1. Token classes
//
class SimpleIdentifierToken: Token {}
class SimpleNumericLiteralToken: Token {}
class SimpleStringLiteralToken: Token {}
class SimpleOperatorToken: Token {}
class SimpleNewlineToken: Token {}
class SimpleSymbolToken: Token {}

//
//MARK: Type 2. LecicalContext type
//
struct SimpleContext: LexicalContextType {
    fileprivate(set) var rawValue: Int
    init(rawValue: Int) {self.rawValue = rawValue}
    
    static let Initial = SimpleContext(rawValue: 1<<0)  //Initial context: the only context for SimpleTokenizer
}

extension SimpleContext: Hashable {
    var hashValue: Int {return rawValue}
}

//
//MARK: Type 3. Tokenizer class
//
class SimpleTokenizer: TokenizerBase<SimpleContext> {
    private static let __matchers: [(String,TM.TokenizingProc)] = [
        ("\\h*([_$a-zA-Z][_$a-zA-Z0-9]*)", {s,r in SimpleIdentifierToken(s,r)}),
        ("\\h*([-+]?[0-9]+(?:\\.[0-9]+)?(?:[eE][-+]?[0-9]+)?)", {s,r in SimpleNumericLiteralToken(s,r)}),
        ("\\h*('(?:[^'\\\\]|\\\\'|\\\\\\\\)*'|\"(?:[^\"\\\\]|\\\\\"|\\\\\\\\)*\")", {s,r in SimpleStringLiteralToken(s,r)}),
        ("\\h*(--|\\+\\+|<<|>>|>>>|==|!=|>=|<=|===|!==|\\?\\?|\\+=|-=|\\*=|/=|"
            + "^=|&=|\\|=|&&|\\|\\||&&=|\\|\\|=|\\?\\?=|<<=|>>=|>>>=)", {s,r in SimpleOperatorToken(s,r)}),
        ("\\h*(?://.*)?(\n\r|\n|\r)", {s,r in SimpleNewlineToken(s,r)}),
        ("\\h*([^_$0-9a-zA-Z'\"\n\r])", {s,r in SimpleSymbolToken(s,r)}),
        ]
    private static let _matchers: [TM] = __matchers.map{TM($0.0,SimpleContext.Initial,$0.1)}
    override var matchers: [TM] {
        return SimpleTokenizer._matchers
    }
    override init(string: String?) {
        super.init(string: string)
    }
}
