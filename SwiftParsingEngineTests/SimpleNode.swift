//
//  SimpleNode.swift
//  SwiftParsingEngine
//
//  Created by 開発 on 2015/9/3.
//  Copyright © 2015-2017 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation
import SwiftParsingEngine

class SimpleNode: NodeBase, CustomDebugStringConvertible {
    var debugDescription: String {return String(describing: type(of: self))}
}

class SimpleScriptNode: SimpleNode {
    ///SimpleStatementNode or SimpleDeclarationNode
    var childNodes:[NodeBase] = []
    
    override var debugDescription: String {
        return childNodes.map{String(reflecting: $0)}.joined(separator: ";")
    }
}

//class SimpleStatementNode: SimpleNode {}
//class SimpleDeclarationNode: SimpleNode {}
class SimpleVariableDeclarationNode: SimpleNode {
    var variable: NodeBase
    var initial: NodeBase
    init(variable: NodeBase, initial: NodeBase) {
        self.variable = variable
        self.initial = initial
    }
    
    override var debugDescription: String {
        return "var \(variable) = \(initial)"
    }
}

//class SimpleExpressionNode: SimpleNode {}

class SimpleIfNode: SimpleNode {
    var condition: NodeBase
    var ifClause: NodeBase
    var elseClause: NodeBase?
    init(condition: NodeBase, ifClause: NodeBase, elseClause: NodeBase? = nil) {
        self.condition = condition
        self.ifClause = ifClause
        self.elseClause = elseClause
    }
    
    override var debugDescription: String {
        return "if( \(condition) ) {\(ifClause)}" + (elseClause != nil ? " else {\(elseClause!)}" : "")
    }
}
class SimpleWhileNode: SimpleNode {
    var condition: NodeBase
    var codeBlock: NodeBase
    init(condition: NodeBase, codeBlock: NodeBase) {
        self.condition = condition
        self.codeBlock = codeBlock
    }
    
    override var debugDescription: String {
        return "while( \(condition) ) {\(codeBlock)}"
    }
}

class SimpleBinaryNode: SimpleNode {
    var lhs: NodeBase
    var rhs: NodeBase
    var operation: String
    init(lhs: NodeBase, operation: String, rhs: NodeBase) {
        self.lhs = lhs
        self.operation = operation
        self.rhs = rhs
    }
    static func createWithNodes(_ nodes: [NodeBase]) -> NodeBase {
        assert(nodes.count > 0)
        var resultNode = nodes[0]
        var index = 1
        while index < nodes.count {
            assert(index + 2 <= nodes.count)
            let operation = (nodes[index] as! TerminalNode).token.string
            let newNode = SimpleBinaryNode(lhs: resultNode, operation: operation, rhs: nodes[index + 1])
            index += 2
            resultNode = newNode
        }
        return resultNode
    }
    
    override var debugDescription: String {
        return "(\(lhs))\(operation)(\(rhs))"
    }
}
class SimpleUnaryNode: SimpleNode {
    var operation: String
    var argument: NodeBase
    init(operation: String, argument: NodeBase) {
        self.operation = operation
        self.argument = argument
    }
    
    override var debugDescription: String {
        return "\(operation)(\(argument))"
    }
}
class SimpleFuncallNode: SimpleNode {
    var function: NodeBase
    var arguments: NodeBase
    init(function: NodeBase, arguments: NodeBase) {
        self.function = function
        self.arguments = arguments
    }
    static func createWithNodes(_ nodes: [NodeBase]) -> NodeBase {
        assert(nodes.count > 0)
        var resultNode = nodes[0]
        var index = 1
        while index < nodes.count {
            assert(index + 1 <= nodes.count)
            if let tNode = nodes[index] as? TerminalNode {
                resultNode = SimpleMemberNode(target: resultNode, name: tNode.token.string)
            } else {
                resultNode = SimpleFuncallNode(function: resultNode, arguments: nodes[index])
            }
            index += 1
        }
        return resultNode
    }
    
    override var debugDescription: String {
        return "(\(function))(\(arguments))"
    }
}

class SimpleVariableNode: SimpleNode {
    var name: String
    init(name: String) {
        self.name = name
    }
    class func createWithToken(_ token: Token) -> NodeBase {
        switch token.string {
            case "true", "false":
                return SimpleBoolNode(string: token.string)
            case "nil":
                return SimpleNilNode()
        default:
            return SimpleVariableNode(name: token.string)
        }
    }
    
    override var debugDescription: String {
        return name
    }
}

class SimpleNumericNode: SimpleNode {
    var value: Double
    init(string: String) {
        if let value = Double(string) {
            self.value = value
        } else {
            fatalError("\(string.debugDescription) cannot be converted to Double")
        }
    }
    
    override var debugDescription: String {
        return String(value)
    }
}

class SimpleStringNode: SimpleNode {
    static var regex = try! NSRegularExpression(pattern: "\\\\([\\\\'\"])", options: [])
    var value: String
    init(token: Token) {
        let range = token.string.characters.index(after: token.string.startIndex)..<token.string.characters.index(before: token.string.endIndex)
        let string = token.string[range]
        let nsRange = NSRange(0..<string.utf16.count)
        self.value = SimpleStringNode.regex.stringByReplacingMatches(in: string, options: [], range: nsRange, withTemplate: "$1")
    }
    
    override var debugDescription: String {
        return value.debugDescription
    }
}

class SimpleBoolNode: SimpleNode {
    var value: Bool
    init(string: String) {
        if string == "true" {
            value = true
        } else if string == "false" {
            value = false
        } else {
            fatalError("Bool value must be 'true' or 'false'")
        }
    }
    
    override var debugDescription: String {
        return String(value)
    }
}

class SimpleNilNode: SimpleNode {
    override var debugDescription: String {
        return "nil"
    }
}
//class SimpleFactorNode: SimpleNode {}

class SimpleMemberNode: SimpleNode {
    var name: String
    var target: NodeBase
    init(target: NodeBase, name: String) {
        self.target = target
        self.name = name
    }
    
    override var debugDescription: String {
        return "(\(target)).\(name)"
    }
}

class SimpleBlockNode: SimpleNode {
    var childNodes: [NodeBase] = []
    
    override var debugDescription: String {
        return childNodes.map{String(reflecting: $0)}.joined(separator: ";")
    }
}
//class SimpleParameterNode: SimpleNode {}
