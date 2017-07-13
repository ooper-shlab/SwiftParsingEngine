//
//  NodeBase.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/27.
//  Copyright © 2015-2017 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation

open class NodeBase {
    public init() {}
}

open class TerminalNode: NodeBase, CustomDebugStringConvertible {
    open var token: Token
    
    public init(token: Token) {
        self.token = token
    }
    
    open var debugDescription: String {
        return "`\(token.string)`"
    }
}
