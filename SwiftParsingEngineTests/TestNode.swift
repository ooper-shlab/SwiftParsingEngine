//
//  Node.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/27.
//  Copyright © 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation
import SwiftParsingEngine

class RootNode: NodeBase {}

class StatementNode: NodeBase {}

class BlockNode: NodeBase {}

class ExpressionNode: NodeBase {}

class PrefixExpressionNode: NodeBase {}

class PostfixExpressionNode: NodeBase {}

class BinaryExpressionNode: NodeBase {}

class BinaryTailNode: NodeBase {}

class ForStatementNode: NodeBase {}

class IfStatementNode: NodeBase {}

class HTMLOutputNode: NodeBase {
    var text: String = ""
    class func createNode(childNodes: [NodeBase]) -> HTMLOutputNode {
        var text = ""
        for node in childNodes {
            switch node {
            case let t as TerminalNode:
                //print(t)
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