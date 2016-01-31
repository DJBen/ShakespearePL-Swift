//
//  Parser.swift
//  Shakespeare
//
//  Created by Sihao Lu on 1/20/16.
//  Copyright © 2016 Sihao Lu. All rights reserved.
//

import Foundation

public class Parser {
    
    enum State {
        case Start // Expect title
        case Title // Expect character declaration
        case CharacterDeclaration // Expect more character declaration (= to denote the same one) or act
        case Act // Expect scene
        case Scene // Expect = or stage
        case Stage // Expect =, character speaking, scene or act
        case CharacterSpeaking // Expect = or dialogue
        case Dialogue // Expect = or stage
        
        static let allStates: [State] = [.Start, .Title, .CharacterDeclaration, .Act, .Scene, .Stage, .CharacterSpeaking, .Dialogue]
        
        private static let nextStateMappings: [State: [State]] = [
            .Start: [.Title],
            .Title: [.CharacterDeclaration],
            .CharacterDeclaration: [.CharacterDeclaration, .Act],
            .Act: [.Scene],
            .Scene: [.Scene, .Stage, .CharacterSpeaking],
            .Stage: [.Stage, .CharacterSpeaking, .Scene, .Act],
            .CharacterSpeaking: [.CharacterSpeaking, .Dialogue],
            .Dialogue: [.Dialogue, .Stage, .CharacterSpeaking, .Act, .Scene]
        ]
        
        var expectedNextStates: [State] {
            return State.nextStateMappings[self]!
        }
    }
    
    public enum ParseError: ErrorType {
        case ExpectedPuctuation
        case ExpectedConjunction
        case UnexpectedToken(Token)
        case NumberOfCharactersOnStage
        case CharactersDoNotExist(Set<String>)
        case ExpectedExpression(String)
        case DuplicateQuestion
        case MissingQuestion
        case ExpectedVerb
        case CharacterNotOnStage(String)
    }
    
    private var currentAct: String?
    private var currentScene: String?
    private var charactersOnStage: Set<String> = []
    private var currentSpeakingCharacter: String?
    private var otherCharacter: String {
        let set = Set<String>([currentSpeakingCharacter!])
        return charactersOnStage.subtract(set).first!
    }
    private var state: State = .Start
    private var hangingQuestion: CompareNode?
    
    private let tokens: [Token]
    private var index = 0
    
    init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    public init(input: String) {
        let tokens = Tokenizer.tokenize(input)
        self.tokens = tokens
    }
    
    var tokensAvailable: Bool {
        return index < tokens.count
    }
    
    func peekCurrentToken() -> Token? {
        guard index < tokens.count else {
            return nil
        }
        return tokens[index]
    }
    
    func popCurrentToken() -> Token {
        return tokens[index++]
    }
    
    public func parse() throws -> [Node] {
        var nodes: [Node] = []
        while tokensAvailable {
            switch state {
            case .Start:
                break
            case .Title:
                try parseTitle()
            case .CharacterDeclaration:
                nodes.append(try parseCharacter())
            case .Act:
                try parseAct()
            case .Scene:
                nodes.append(try parseScene())
            case .Stage:
                try parseStage()
            case .CharacterSpeaking:
                try parseCharacterSpeaking()
            case .Dialogue:
                if let node = try parseDialogue() {
                    nodes.append(node)
                }
            }
            try attemptToTransitionToNextState()
        }
        return nodes
    }
    
    private func attemptToTransitionToNextState() throws {
        guard let token = peekCurrentToken() else {
            return
        }
        switch state {
        case .Start:
            state = .Title
        case .Title:
            // Transition automatically when met punctuation
            break
        case .CharacterDeclaration:
            if case .Lexeme(.Character(_)) = token {
                break
            } else {
                state = try nextStateForToken(token)
            }
        case .Act:
            // Transition automatically when act line finishes
            break
        case .Scene:
            if case .Scene(_, _) = token {
                break
            } else {
                state = try nextStateForToken(token)
            }
        case .Stage:
            if case .Enter(_) = token {
                break
            } else if case .Exit(_) = token {
                break
            } else {
                state = try nextStateForToken(token)
            }
        case .CharacterSpeaking:
            state = try nextStateForToken(token)
        case .Dialogue:
            if case .Lexeme(_) = token {
                break
            } else {
                state = try nextStateForToken(token)
            }
        }
    }

    private func parseTitle() throws {
        // Ensure token validity
        while tokensAvailable {
            let token = popCurrentToken()
            if case .Lexeme(.Punctuation) = token {
                state = .CharacterDeclaration
                break
            }
        }
        if state != .CharacterDeclaration {
            throw ParseError.ExpectedPuctuation
        }
    }
    
    private func parseCharacter() throws -> Node {
        guard let token = peekCurrentToken() else {
            throw ParseError.ExpectedPuctuation
        }
        guard case .Lexeme(.Character(_)) = token else {
            throw ParseError.UnexpectedToken(token)
        }
        var node: Node?
        var shouldContinue = true
        while tokensAvailable && shouldContinue {
            let token = popCurrentToken()
            switch token {
            case .Lexeme(.Character(let character)):
                if node != nil {
                    break
                }
                node = CharacterDeclarationNode(name: character)
            case .Lexeme(.Punctuation):
                // Terminate character parsing
                shouldContinue = false
            default:
                break
            }
        }
        return node!
    }
    
    private func parseAct() throws {
        guard let token = peekCurrentToken() else {
            return
        }
        guard case .Act(let identifier, _) = token else {
            throw ParseError.UnexpectedToken(token)
        }
        popCurrentToken()
        currentAct = identifier
        state = .Scene
    }
    
    private func parseScene() throws -> Node {
        guard let token = peekCurrentToken() else {
            throw ParseError.ExpectedPuctuation
        }
        guard case .Scene(let identifier, _) = token else {
            throw ParseError.UnexpectedToken(token)
        }
        popCurrentToken()
        currentScene = identifier
        return GotoTagNode(tag: currentAct! + "." + currentScene!)
    }
    
    private func parseStage() throws {
        guard let token = peekCurrentToken() else {
            return
        }
        if case .Enter(let characters) = token {
            charactersOnStage.unionInPlace(characters)
        } else if case .Exit(let characters) = token {
            // Make sure every character that is required to exit exists on stage
            guard charactersOnStage.intersect(characters) == characters else {
                throw ParseError.CharactersDoNotExist(characters.subtract(charactersOnStage.intersect(characters)))
            }
            charactersOnStage.subtractInPlace(characters)
        } else {
            throw ParseError.UnexpectedToken(token)
        }
        popCurrentToken()
    }
    
    private func parseCharacterSpeaking() throws {
        if charactersOnStage.count > 2 {
            throw ParseError.NumberOfCharactersOnStage
        }
        if charactersOnStage.count < 2 {
            throw ParseError.NumberOfCharactersOnStage
        }
        guard let token = peekCurrentToken() else {
            return
        }
        if case .Speaking(let name) = token {
            currentSpeakingCharacter = name
            guard charactersOnStage.contains(name) else {
                throw ParseError.CharacterNotOnStage(name)
            }
        } else {
            throw ParseError.UnexpectedToken(token)
        }
        popCurrentToken()
    }
    
    private func parseDialogue() throws -> Node? {
        guard let token = peekCurrentToken() else {
            throw ParseError.ExpectedPuctuation
        }
        switch token {
        // If the token is one of the commands below - consume the token
        case .ConditionalJump(_, _), .Jump(_), .PrintNumber, .PrintCharacter, .ScanCharacter, .ScanNumber, .PushStack, .PopStack:
            popCurrentToken()
        default:
            break
        }
        switch token {
        case .Jump(scene: let scene):
            // TODO: check scene exists
            return JumpNode(tag: currentAct! + "." + scene)
        case .PrintCharacter:
            return PrintCharacterNode(variable: otherCharacter)
        case .PrintNumber:
            return PrintNumberNode(variable: otherCharacter)
        case .ScanCharacter:
            return ScanCharacterNode(variable: otherCharacter)
        case .ScanNumber:
            return ScanNumberNode(variable: otherCharacter)
        case .PushStack:
            return PushStackNode(variable: otherCharacter)
        case .PopStack:
            return PopStackNode(variable: otherCharacter)
        case let .ConditionalJump(positive, scene: scene):
            guard let question = hangingQuestion else {
                throw ParseError.MissingQuestion
            }
            hangingQuestion = nil
            let processedQuestion = positive ? question : question.negatedComparison
            return ConditionalJumpNode(test: processedQuestion, jump: JumpNode(tag: currentAct! + "." + scene))
        case .Lexeme(let lexeme):
            switch lexeme {
            case .SecondPerson:
                // You + noun or You are as x as noun
                return try parseAssignment()
            case .Be:
                // Question
                guard hangingQuestion == nil else {
                    throw ParseError.DuplicateQuestion
                }
                hangingQuestion = try parseQuestion()
                return nil
            default:
                throw ParseError.UnexpectedToken(token)
            }
        default:
            throw ParseError.UnexpectedToken(token)
        }
    }
    
    private func parseQuestion() throws -> CompareNode {
        // Consume "be" verb
        popCurrentToken()
        var comparison: CompareNode.Predicate?
        var lhs: ExpressionNode?
        var rhs: ExpressionNode?
        var lhsTokens: [Token] = []
        var rhsTokens: [Token] = []
        while tokensAvailable {
            let token = popCurrentToken()
            switch token {
            case .Lexeme(.Compare(let type)):
                guard lhsTokens.isEmpty == false else {
                    throw ParseError.ExpectedExpression("Left hand side expression")
                }
                comparison = CompareNode.Predicate(rawValue: type.rawValue)!
            case .Lexeme(.Punctuation):
                guard comparison != nil else {
                    throw ParseError.ExpectedExpression("Comparison")
                }
                guard rhsTokens.isEmpty == false else {
                    throw ParseError.ExpectedExpression("Right hand side expression")
                }
                lhs = try parseExpressionTokens(lhsTokens)
                rhs = try parseExpressionTokens(rhsTokens)
                return CompareNode(lhs: lhs!, rhs: rhs!, predicate: comparison!)
            default:
                if comparison == nil {
                    lhsTokens.append(token)
                } else {
                    rhsTokens.append(token)
                }
            }
        }
        throw ParseError.ExpectedPuctuation
    }
    
    private func parseExpressionTokens(tokens: [Token], multiplier: Int = 1) throws -> ExpressionNode {
        let firstToken = tokens.first!
        switch firstToken {
        case .Lexeme(.SecondPerson), .Lexeme(.SecondPersonReflexive):
            return VariableNode(name: otherCharacter)
        case .Lexeme(.FirstPerson), .Lexeme(.FirstPersonReflexive):
            return VariableNode(name: currentSpeakingCharacter!)
        case .Lexeme(.Character(let name)):
            return VariableNode(name: name)
        case .Lexeme(.UnaryOperation(let operation)):
            return UnaryOperationNode(type: UnaryOperationNode.ExpressionType(rawValue: operation.rawValue)!, subExpression: try parseExpressionTokens(Array(tokens[1..<tokens.count])))
        case .Lexeme(.BinaryOperation(let operation)):
            func indexOfConjunction() throws -> Int {
                var binOpLayer = 0
                for (i, token) in tokens[1..<tokens.count].enumerate() {
                    switch token {
                    case .Lexeme(.BinaryOperation(_)):
                        binOpLayer += 1
                    case .Lexeme(.Conjunction):
                        binOpLayer -= 1
                        if binOpLayer < 0 {
                            return i
                        }
                    default:
                        break
                    }
                }
                throw ParseError.ExpectedExpression("Conjunction")
            }
            let conjunctionIndex = try indexOfConjunction()
            let lhs = try parseExpressionTokens(Array(tokens[1 ..< conjunctionIndex + 1]))
            let rhs = try parseExpressionTokens(Array(tokens[conjunctionIndex + 2 ..< tokens.count]))
            return BinaryOperationNode(type: BinaryOperationNode.ExpressionType(rawValue: operation.rawValue)!, lhs: lhs, rhs: rhs)
        case .Lexeme(.Other(let word)):
            func multiplierFromAdjective(word: String) -> Int? {
                if tokens.count == 1 {
                    return nil
                }
                if case .Lexeme(.Other(_)) = tokens[1] {
                    if word.match("\\b\(SearchingWord.Multiple([.PositiveNoun, .NegativeNoun, .NeutralNoun]).regexPatternWithNoWordBoundaries)('|'s)?\\b") != nil {
                        return 1
                    }
                    return 2
                } else {
                    return nil
                }
            }
            if let m = multiplierFromAdjective(word) {
                // Adjective
                return try parseExpressionTokens(Array(tokens[1..<tokens.count]), multiplier: m * multiplier)
            } else {
                // Noun
                if SearchingWord.NegativeNoun.words.contains(word) {
                    return ValueNode(value: multiplier * -1)
                } else if SearchingWord.Nothing.words.contains(word) {
                    return ValueNode(value: 0)
                } else {
                    return ValueNode(value: multiplier)
                }
            }
        case .Lexeme(.FirstPersonPossessive), .Lexeme(.SecondPersonPossessive), .Lexeme(.ThirdPersonPossessive):
            // Ignore the possessives
            return try parseExpressionTokens(Array(tokens[1..<tokens.count]), multiplier: multiplier)
        default:
            throw ParseError.UnexpectedToken(firstToken)
        }
    }
    
    private func parseAssignment() throws -> AssignmentNode {
        let token = popCurrentToken()
        guard case .Lexeme(.SecondPerson) = token else {
            throw ParseError.UnexpectedToken(token)
        }
        let variable = VariableNode(name: otherCharacter)

        func tokensUntilPunctuation() throws -> [Token] {
            var tokens: [Token] = []
            while tokensAvailable {
                let token = popCurrentToken()
                switch token {
                case .Lexeme(.Punctuation):
                    return tokens
                default:
                    tokens.append(token)
                }
            }
            throw ParseError.ExpectedPuctuation
        }
        
        if case .Lexeme(.Be) = peekCurrentToken()! {
            popCurrentToken()
            // You are as x as + noun
            let comparisonToken = popCurrentToken()
            guard case .Lexeme(.Compare(.Equals)) = comparisonToken else {
                throw ParseError.ExpectedExpression("Equality")
            }
            let tokens = try tokensUntilPunctuation()
            return AssignmentNode(variable: variable, expression: try parseExpressionTokens(tokens))
        } else {
            // You + noun
            let tokens = try tokensUntilPunctuation()
            return AssignmentNode(variable: variable, expression: try parseExpressionTokens(tokens))
        }
    }
    
    private func nextStateForToken(token: Token) throws -> State {
        let possibleStatesForToken = Set<State>(token.possibleStates)
        let validNextStates = Set<State>(state.expectedNextStates)
        let nextStates = possibleStatesForToken.intersect(validNextStates)
        if nextStates.count == 0 {
            throw ParseError.UnexpectedToken(token)
        } else if nextStates.count == 1 {
            return nextStates.first!
        } else {
            // Undetermined, throw error for now
            fatalError()
        }
    }
}

extension Token {
    // Possible states in which the token appears
    var possibleStates: [Parser.State] {
        get {
            switch self {
            case .Act(_, _):
                return [.Act]
            case .Scene(_):
                return [.Scene]
            case .ConditionalJump(_, _), .Jump(_), .PrintNumber, .PrintCharacter, .ScanCharacter, .ScanNumber, .PushStack, .PopStack:
                return [.Dialogue]
            case .Speaking(_):
                return [.CharacterSpeaking]
            case .Enter(_), .Exit(_):
                return [.Stage]
            case .Other(_):
                return [.Dialogue, .CharacterDeclaration, .Title]
            default:
                return [.Dialogue, .CharacterDeclaration, .Title]
            }
        }
    }
}
