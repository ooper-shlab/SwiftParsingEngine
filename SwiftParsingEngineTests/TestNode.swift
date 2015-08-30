//
//  Node.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/27.
//  Copyright © 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation
import SwiftParsingEngine

class RootNode: NodeBase {
    override class func createNode(childNodes: [NodeBase]) -> Self {
        fatalError()
    }
}

class StatementNode: NodeBase {
    override class func createNode(childNodes: [NodeBase]) -> Self {
        fatalError()
    }
}

class BlockNode: NodeBase {
    override class func createNode(childNodes: [NodeBase]) -> Self {
        fatalError()
    }
}

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

class HTMLOutputNode: NodeBase {
    var text: String = ""
    override class func createNode(childNodes: [NodeBase]) -> HTMLOutputNode {
        var text = ""
        for node in childNodes {
            switch node {
            case let t as TerminalNode:
                print(t)
                text += t.token.string
                break
            default:
                break
            }
        }
        return HTMLOutputNode(text: text)
    }
    
    init(text: String) {
        self.text = text
        super.init()
    }
}