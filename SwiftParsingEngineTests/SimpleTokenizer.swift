//
//  SimpleTokenizer.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/9/1.
//  Copyright © 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation
import SwiftParsingEngine

/* ---------------------------------------------------------------------------------------- *
    [Tokenizer]

    In order to uitlize SwiftParsingEngine, you need to define three categories of types,
    tokenizer, parser and node. This file describes about definitions in Tokenizer category.

    In the tokenizer category, you declare three kinds of types.

    Type 1. Token classes
    Type 2. LecicalState type
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
    private(set) var rawValue: Int
    init(rawValue: Int) {self.rawValue = rawValue}
    
    static let Initial = SimpleContext(rawValue: 1<<0)  //Initial context: the only context for SimpleTokenizer
}

//
//MARK: Type 3. Tokenizer class
//
class SimpleTokenizer: TokenizerBase<SimpleContext> {
    override var matchers: [TM] {
        return [
            ("\\h*([_$a-zA-Z][_$a-zA-Z0-9]*)", {SimpleIdentifierToken($0)}),
            ("\\h*([-+]?[0-9]+(?:\\.[0-9]+)?(?:[eE][-+]?[0-9]+)?)", {SimpleNumericLiteralToken($0)}),
            ("\\h*('(?:[^'\\\\]|\\\\'|\\\\\\\\)*'|\"(?:[^\"\\\\]|\\\\\"|\\\\\\\\)*\")", {SimpleStringLiteralToken($0)}),
            ("\\h*(--|\\+\\+|<<|>>|>>>|==|!=|>=|<=|===|!==|\\?\\?|\\+=|-=|\\*=|/=|"
                + "^=|&=|\\|=|&&|\\|\\||&&=|\\|\\|=|\\?\\?=)", {SimpleOperatorToken($0)}),
            ("\\h*(?://.*)?(\n\r|\n|\r)", {SimpleNewlineToken($0)}),
            ("\\h*([^_$0-9a-zA-Z'\"\n\r])", {SimpleSymbolToken($0)}),
            ].map{TM($0,SimpleContext.Initial,$1)}
    }
    override init(string: String?) {
        super.init(string: string)
    }
}
