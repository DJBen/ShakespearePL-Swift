//
//  Node.swift
//  Shakespeare
//
//  Created by Sihao Lu on 1/27/16.
//  Copyright © 2016 Sihao Lu. All rights reserved.
//

public protocol Node: CustomStringConvertible { }

public struct GotoTagNode: Node {
    let tag: String
    public var description: String {
        return "Tag(\(tag))"
    }
}

public struct CharacterDeclarationNode: Node {
    public let name: String
    public var description: String {
        return "Character(name: \(name))"
    }
}

public struct ScanNumberNode: Node {
    let variable: String
    public var description: String {
        return "ScanNumber(\(variable))"
    }
}

public struct ScanCharacterNode: Node {
    let variable: String
    public var description: String {
        return "ScanCharacter(\(variable))"
    }
}

public struct PrintCharacterNode: Node {
    let variable: String
    public var description: String {
        return "PrintCharacter(\(variable))"
    }
}

public struct PrintNumberNode: Node {
    let variable: String
    public var description: String {
        return "PrintNumber(\(variable))"
    }
}

public struct PushStackNode: Node {
    let variable: String
    public var description: String {
        return "PushStack(\(variable))"
    }
}

public struct PopStackNode: Node {
    let variable: String
    public var description: String {
        return "PopStack(\(variable))"
    }
}

public protocol ExpressionNode: Node { }

public protocol OperationNode: ExpressionNode { }

public struct VariableNode: ExpressionNode {
    public let name: String
    public var description: String {
        return "Variable(name: \(name))"
    }
}

public struct AssignmentNode: Node {
    public let variable: VariableNode
    public let expression: ExpressionNode
    public var description: String {
        return "Assign(variable: \(variable), expr: \(expression))"
    }
}

public struct ValueNode: ExpressionNode {
    public let value: Int
    public var description: String {
        return "Value(\(value))"
    }
}

public struct UnaryOperationNode: OperationNode {
    public enum ExpressionType: String {
        case Twice = "2x"
        case Square = "^2"
        case Cube = "^3"
        case SquareRoot = "sqrt"
    }
    
    let type: ExpressionType
    let subExpression: ExpressionNode
    public var description: String {
        return "UnaryOperation(\(type.rawValue), expr: \(subExpression))"
    }
}

public struct BinaryOperationNode: OperationNode {
    public enum ExpressionType: String {
        case Add = "+"
        case Subtract = "-"
        case Product = "*"
        case Divide = "/"
        case Modulo = "%"
    }
    let type: ExpressionType
    let lhs: ExpressionNode
    let rhs: ExpressionNode
    public var description: String {
        return "BinaryOperation(\(type.rawValue), lhs: \(lhs), rhs: \(rhs))"
    }
}

public struct CompareNode: Node {
    public let lhs: ExpressionNode
    public let rhs: ExpressionNode
    public enum Predicate: String {
        case Equals = "="
        case LessThan = "<"
        case GreaterThan = ">"
        case NotEqual = "!="
        case LessThanOrEqual = "<="
        case GreaterThanOrEqual = ">="
    }
    public let predicate: Predicate
    public var description: String {
        return "Compare(\(predicate.rawValue), lhs: \(lhs), rhs: \(rhs))"
    }
    var negatedComparison: CompareNode {
        let negatedPredicate: Predicate
        switch predicate {
        case .Equals: negatedPredicate = .NotEqual
        case .LessThan: negatedPredicate = .GreaterThanOrEqual
        case .GreaterThan: negatedPredicate = .LessThanOrEqual
        case .NotEqual: negatedPredicate = .Equals
        case .LessThanOrEqual: negatedPredicate = .GreaterThan
        case .GreaterThanOrEqual: negatedPredicate = .LessThan
        }
        return CompareNode(lhs: lhs, rhs: rhs, predicate: negatedPredicate)
    }
}

public struct ConditionalJumpNode: Node {
    public let test: CompareNode
    public let jump: JumpNode
    public var description: String {
        return "ConditionalJump(test: \(test), \(jump))"
    }
}

public struct JumpNode: Node {
    public let tag: String
    public var description: String {
        return "Jump(\(tag))"
    }
}
