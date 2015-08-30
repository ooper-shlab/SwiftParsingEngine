//
//  Node.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/27.
//  Copyright © 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation
import SwiftParsingEngine

class ExpressionNode: NodeBase {
    override class func createNode(childNodes: [NodeBase]) -> Self {
        fatalError()
    }
}

class PrefixExpressionNode: NodeBase {
    override class func createNode(childNodes: [NodeBase]) -> Self {
        fatalError()
    }
}

class BinaryExpressionNode: NodeBase {
    override class func createNode(childNodes: [NodeBase]) -> Self {
        fatalError()
    }
}

class PrefixOperatorNode: NodeBase {
    override class func createNode(childNodes: [NodeBase]) -> Self {
        fatalError()
    }
}

class ForStatementNode: NodeBase {
    override class func createNode(childNodes: [NodeBase]) -> Self {
        fatalError()
    }
}

class IfStatementNode: NodeBase {
    override class func createNode(childNodes: [NodeBase]) -> Self {
        fatalError()
    }
}
