//
//  Tokenizer.swift
//  Shakespeare
//
//  Created by Sihao Lu on 1/20/16.
//  Copyright © 2016 Sihao Lu. All rights reserved.
//

import Foundation

public enum Token {
    
    public enum Lexemes {
        
        public enum ComparisonType: String {
            case LessThan = "<"
            case Equals = "="
            case GreaterThan = ">"
        }
        
        case Compare(ComparisonType)
        case Be
        case FirstPerson
        case FirstPersonPossessive
        case FirstPersonReflexive
        case SecondPerson
        case SecondPersonPossessive
        case SecondPersonReflexive
        case ThirdPersonPossessive
        case Character(String)
        case Conjunction
        case Punctuation
        
        public enum BinaryOperationType: String {
            case Add = "+"
            case Subtract = "-"
            case Product = "*"
            case Divide = "/"
            case Modulo = "%"
        }
        
        case BinaryOperation(BinaryOperationType)
        
        public enum UnaryOperationType: String {
            case Twice = "2x"
            case Square = "^2"
            case Cube = "^3"
            case SquareRoot = "sqrt"
        }
        
        case UnaryOperation(UnaryOperationType)
        case Other(String)
    }
    
    case Act(identifier: String, description: String)
    case Scene(identifier: String, description: String)
    case Enter(names: Set<String>)
    case Exit(names: Set<String>)
    case Speaking(name: String)
    case Lexeme(Lexemes)
    case PrintNumber
    case PrintCharacter
    case ScanNumber
    case ScanCharacter
    case Jump(scene: String)
    case ConditionalJump(Bool, scene: String)
    case PushStack
    case PopStack
    case Other(String)
}

public final class Tokenizer: NSObject {
    
    typealias TokenGenerator = (String, [String]) -> Token?
    
    static let tokenList: [(String, NSRegularExpressionOptions, TokenGenerator)] = [
        ("[ \t\n]", [], { _, _ in nil }),
        ("Act (M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})): (.*)", [], { _, tokens in .Act(identifier: tokens[0], description: tokens[4]) }),
        ("Scene (M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})): (.*)", [], { _, tokens in .Scene(identifier: tokens[0], description: tokens[4]) }),
        ("\\[Enter ([A-Za-z\\s]+) and ([A-Za-z\\s]+)\\]", [], { _, tokens in .Enter(names: [tokens[0].capitalizedString, tokens[1].capitalizedString]) }),
        ("\\[Enter ([A-Za-z\\s]+)\\]", [], { _, tokens in .Enter(names: [tokens[0].capitalizedString]) }),
        ("\\[Exeunt\\s+([A-Za-z\\s]+) and ([A-Za-z\\s]+)\\]", [], { _, tokens in .Exit(names: [tokens[0].capitalizedString, tokens[1].capitalizedString]) }),
        ("\\[Exit ([A-Za-z\\s]+)\\]", [], { _, tokens in .Exit(names: [tokens[0].capitalizedString]) }),
        ("\\[Exeunt\\]", [], { _, tokens in .Exit(names: []) }),
        ("([A-Za-z\\s]+):", [], { _, tokens in .Speaking(name: tokens[0]) }),
        // Sentence components
        ("Listen to \(SearchingWord.SecondPersonPossessive.regexPattern) heart[.!?]", [.CaseInsensitive], { _, _ in .ScanNumber }),
        ("Open \(SearchingWord.SecondPersonPossessive.regexPattern) mind[.!?]", [.CaseInsensitive], { _, _ in .ScanCharacter }),
        ("Speak \(SearchingWord.SecondPersonPossessive.regexPattern) mind[.!?]", [.CaseInsensitive], { _, _ in .PrintCharacter }),
        ("Open \(SearchingWord.SecondPersonPossessive.regexPattern) heart[.!?]", [.CaseInsensitive], { _, _ in .PrintNumber }),
        ("(the\\s+product\\s+of|the\\s+sum\\s+of|the\\s+remainder\\s+of\\s+the\\s+quotient\\s+between|the\\s+quotient\\s+between|the\\s+difference\\s+between)", [],
            { _, tokens in
                if tokens[0].lowercaseString.rangeOfString("product") != nil {
                    return .Lexeme(.BinaryOperation(.Product))
                } else if tokens[0].lowercaseString.rangeOfString("sum") != nil {
                    return .Lexeme(.BinaryOperation(.Add))
                } else if tokens[0].lowercaseString.rangeOfString("difference") != nil {
                    return .Lexeme(.BinaryOperation(.Subtract))
                } else if tokens[0].lowercaseString.rangeOfString("remainder") != nil {
                    return .Lexeme(.BinaryOperation(.Modulo))
                } else {
                    return .Lexeme(.BinaryOperation(.Divide))
                }
            }
        ),
        ("(the\\s+square\\s+of|the\\s+cube\\s+of|twice|the\\s+square\\s+root\\s+of)", [],
            { _, tokens in
                if tokens[0].lowercaseString.rangeOfString("root") != nil {
                    return .Lexeme(.UnaryOperation(.SquareRoot))
                } else if tokens[0].lowercaseString.rangeOfString("twice") != nil {
                    return .Lexeme(.UnaryOperation(.Twice))
                } else if tokens[0].lowercaseString.rangeOfString("cube") != nil {
                    return .Lexeme(.UnaryOperation(.Cube))
                } else {
                    return .Lexeme(.UnaryOperation(.Square))
                }
            }
        ),
        ("If so,\\s+(Let us|we must|we shall) (proceed|return) to scene (M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3}))[.!?]", [.CaseInsensitive], { _, tokens in .ConditionalJump(true, scene: tokens[5]) }),
        ("If not,\\s+(Let us|we must|we shall) (proceed|return) to scene (M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3}))[.!?]", [.CaseInsensitive], { _, tokens in .ConditionalJump(false, scene: tokens[5]) }),
        ("and", [], { _, _ in .Lexeme(.Conjunction) }),
        ("(Let us|we must|we shall) (proceed|return) to scene (M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3}))[.!?]", [.CaseInsensitive], { _, tokens in .Jump(scene: tokens[5]) }),
        ("as\\s+[\\w-/']+\\s+as", [.CaseInsensitive], { _, _ in .Lexeme(.Compare(.Equals)) }),
        ("\(SearchingWord.PositiveComparative.regexPattern)\\s+than", [.CaseInsensitive], { _, _ in .Lexeme(.Compare(.GreaterThan)) }),
        ("more [\\w-/']+ than", [.CaseInsensitive], { _, _ in .Lexeme(.Compare(.GreaterThan)) }),
        ("\(SearchingWord.NegativeComparative.regexPattern)\\s+than", [.CaseInsensitive], { _, _ in .Lexeme(.Compare(.LessThan)) }),
        ("less [\\w-/']+ than", [.CaseInsensitive], { _, _ in .Lexeme(.Compare(.LessThan)) }),
        ("Remember .*[.!?]", [.CaseInsensitive], { _, _ in .PushStack }),
        ("Recall .*[.!?]", [.CaseInsensitive], { _, _ in .PopStack }),
        (SearchingWord.Character.regexPattern, [.CaseInsensitive], { name, _ in .Lexeme(.Character(name.capitalizedString)) }),
        (SearchingWord.SecondPerson.regexPattern, [.CaseInsensitive], { _, _ in .Lexeme(.SecondPerson) }),
        (SearchingWord.SecondPersonReflexive.regexPattern, [.CaseInsensitive], { _, _ in .Lexeme(.SecondPersonReflexive) }),
        (SearchingWord.FirstPerson.regexPattern, [.CaseInsensitive], { _, _ in .Lexeme(.FirstPerson) }),
        (SearchingWord.FirstPersonReflexive.regexPattern, [.CaseInsensitive], { _, _ in .Lexeme(.FirstPersonReflexive) }),
        (SearchingWord.SecondPersonPossessive.regexPattern, [.CaseInsensitive], { _, _ in .Lexeme(.SecondPersonPossessive) }),
        (SearchingWord.FirstPersonPossessive.regexPattern, [.CaseInsensitive], { _, _ in .Lexeme(.FirstPersonPossessive) }),
        (SearchingWord.ThirdPersonPossessive.regexPattern, [.CaseInsensitive], { _, _ in .Lexeme(.ThirdPersonPossessive) }),
        (SearchingWord.Be.regexPattern, [.CaseInsensitive], { _, _ in .Lexeme(.Be) }),
        (SearchingWord.Article.regexPattern, [], { _, _ in nil }),
        ("[\\w-/']+", [], { word, _ in .Lexeme(.Other(word)) }),
        ("[.!?]", [], { _, _ in .Lexeme(.Punctuation) } ),
    ]
    
    public static func tokenize(input: String) -> [Token] {
        var tokens = [Token]()
        var content = input
    
        while (content.characters.count > 0) {
            var matched = false
            
            for (pattern, options, generator) in Tokenizer.tokenList {
                if let result = content.match(pattern, options: options) {
                    let captureGroups = (1..<result.numberOfRanges).map { (content as NSString).substringWithRange(result.rangeAtIndex($0)) }
                    if let t = generator((content as NSString).substringWithRange(result.range), captureGroups) {
                        tokens.append(t)
                    }
                    content = content.substringFromIndex(content.startIndex.advancedBy(result.range.length))
                    matched = true
                    break
                }
            }
            
            if !matched {
                let index = content.startIndex.advancedBy(1)
                tokens.append(.Other(content.substringToIndex(index)))
                content = content.substringFromIndex(index)
            }
        }
        return tokens
    }
}

var expressions = [String: NSRegularExpression]()

extension String {
    func match(regex: String, options: NSRegularExpressionOptions = []) -> NSTextCheckingResult? {
        let expression: NSRegularExpression
        if let exists = expressions[regex] {
            expression = exists
        } else {
            expression = try! NSRegularExpression(pattern: "^\(regex)", options: options)
            expressions[regex] = expression
        }
        
        return expression.firstMatchInString(self, options: [], range: NSMakeRange(0, self.utf16.count))
    }
}
