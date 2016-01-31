//
//  Simulator.swift
//  Shakespeare
//
//  Created by Sihao Lu on 1/31/16.
//  Copyright © 2016 Sihao Lu. All rights reserved.
//

public class Simulator: NSObject {
    
    private let numberProvider: () -> Int
    private let characterProvider: () -> Character
    private var store: [String: Int] = [:]
    private var gotos: [String: Int] = [:]
    
    public override init() {
        numberProvider = {
            return 0
        }
        characterProvider = {
            return Character(UnicodeScalar(0))
        }
        super.init()
    }
    
    public init(numberProvider: () -> Int, characterProvider: () -> Character) {
        self.numberProvider = numberProvider
        self.characterProvider = characterProvider
    }
    
    public func runNodes(nodes: [Node]) {
        // Prerecord goto tags
        for (i, node) in nodes.enumerate() {
            switch node {
            case let goto as GotoTagNode:
                gotos[goto.tag] = i
            default:
                break
            }
        }
        for var i in 0..<nodes.count {
            let node = nodes[i]
            switch node {
            case let scanNumberNode as ScanNumberNode:
                store[scanNumberNode.variable] = numberProvider()
            case let scanCharacterNode as ScanCharacterNode:
                store[scanCharacterNode.variable] = ctoi(characterProvider())
            case let printCharNode as PrintCharacterNode:
                print(itoc(store[printCharNode.variable]!), terminator: "")
            case let printNumberNode as PrintNumberNode:
                print(store[printNumberNode.variable]!, terminator: "")
            case let character as CharacterDeclarationNode:
                store[character.name] = 0
            case let assignment as AssignmentNode:
                store[assignment.variable.name] = evaluate(assignment.expression)
            case let jump as JumpNode:
                i = gotos[jump.tag]!
            case let condJump as ConditionalJumpNode:
                let lhs = evaluate(condJump.test.lhs)
                let rhs = evaluate(condJump.test.rhs)
                let pass: Bool
                switch condJump.test.predicate {
                case .Equals:
                    pass = lhs == rhs
                case .GreaterThan:
                    pass = lhs > rhs
                case .GreaterThanOrEqual:
                    pass = lhs >= rhs
                case .LessThan:
                    pass = lhs < rhs
                case .LessThanOrEqual:
                    pass = lhs <= rhs
                case .NotEqual:
                    pass = lhs != rhs
                }
                if pass {
                    i = gotos[condJump.jump.tag]!
                }
            default:
                break
            }
        }
    }
    
    private func evaluate(expr: ExpressionNode) -> Int {
        switch expr {
        case let variable as VariableNode:
            return store[variable.name]!
        case let value as ValueNode:
            return value.value
        case let binOp as BinaryOperationNode:
            switch binOp.type {
            case .Add:
                return evaluate(binOp.lhs) + evaluate(binOp.rhs)
            case .Subtract:
                return evaluate(binOp.lhs) - evaluate(binOp.rhs)
            case .Product:
                return evaluate(binOp.lhs) * evaluate(binOp.rhs)
            case .Divide:
                return evaluate(binOp.lhs) / evaluate(binOp.rhs)
            case .Modulo:
                return evaluate(binOp.lhs) % evaluate(binOp.rhs)
            }
        case let uniOp as UnaryOperationNode:
            switch uniOp.type {
            case .Twice:
                return 2 * evaluate(uniOp.subExpression)
            case .Square:
                return Int(pow(Double(evaluate(uniOp.subExpression)), 2))
            case .Cube:
                return Int(pow(Double(evaluate(uniOp.subExpression)), 3))
            case .SquareRoot:
                return Int(sqrt(Double(evaluate(uniOp.subExpression))))
            }
        default:
            fatalError()
        }
    }
}

private func ctoi(c: Character) -> Int {
    let s = String(c).unicodeScalars
    return Int(s[s.startIndex].value)
}

private func itoc(i: Int) -> Character {
    return Character(UnicodeScalar(i))
}