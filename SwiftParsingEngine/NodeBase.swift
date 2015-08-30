//
//  NodeBase.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/27.
//  Copyright © 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation

public class NodeBase {
    
    public class func createNode(childNodes: [NodeBase]) -> Self {
        fatalError("Abstract method \(__FUNCTION__) not implemented")
    }
    
    public init() {}
    
}

public class TerminalNode: NodeBase {
    public var token: Token
    
    init(token: Token) {
        self.token = token
    }
}