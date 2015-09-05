//
//  SimpleNode.swift
//  SwiftParsingEngine
//
//  Created by 開発 on 2015/9/3.
//  Copyright © 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation
import SwiftParsingEngine

class SimpleNode: NodeBase {
}

class SimpleScriptNode: SimpleNode {}

class SimpleStatementNode: SimpleNode {}
class SimpleDeclarationNode: SimpleNode {}

class SimpleExpressionNode: SimpleNode {}

class SimpleIfNode: SimpleNode {}
class SimpleWhileNode: SimpleNode {}

class SimpleBinaryNode: SimpleNode {}
class SimpleUnaryNode: SimpleNode {}

class SimpleVariableNode: SimpleNode {}
class SimpleConstantNode: SimpleNode {}
class SimpleFactorNode: SimpleNode {}

class SimpleBlockNode: SimpleNode {}
class SimpleParameterNode: SimpleNode {}