//
//  NodeBase.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/27.
//  Copyright © 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation

public class NodeBase {
    public init() {}
}

public class TerminalNode: NodeBase, CustomDebugStringConvertible {
    public var token: Token
    
    public init(token: Token) {
        self.token = token
    }
    
    public var debugDescription: String {
        return "`\(token.string)`"
    }
}