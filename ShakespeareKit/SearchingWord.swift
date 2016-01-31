//
//  SearchingWords.swift
//  Shakespeare
//
//  Created by Sihao Lu on 1/23/16.
//  Copyright © 2016 Sihao Lu. All rights reserved.
//

private var wordLists: [String: [String]] = [:]

enum SearchingWord {
    case Article
    case Be
    case Character
    case FirstPerson
    case FirstPersonPossessive
    case FirstPersonReflexive
    case NegativeAdjective
    case NegativeComparative
    case NegativeNoun
    case NeutralAdjective
    case NeutralNoun
    case Nothing
    case PositiveAdjective
    case PositiveComparative
    case PositiveNoun
    case SecondPerson
    case SecondPersonPossessive
    case SecondPersonReflexive
    case ThirdPersonPossessive
    case Multiple([SearchingWord])
    
    private var wordListPath: String {
        switch self {
        case .Article:
            return "article"
        case .Be:
            return "be"
        case .Character:
            return "character"
        case .FirstPerson:
            return "first_person"
        case .FirstPersonPossessive:
            return "first_person_possessive"
        case .FirstPersonReflexive:
            return "first_person_reflexive"
        case .NegativeAdjective:
            return "negative_adjective"
        case .NegativeComparative:
            return "negative_comparative"
        case .NegativeNoun:
            return "negative_noun"
        case .NeutralAdjective:
            return "neutral_adjective"
        case .NeutralNoun:
            return "neutral_noun"
        case .Nothing:
            return "nothing"
        case .PositiveAdjective:
            return "positive_adjective"
        case .PositiveComparative:
            return "positive_comparative"
        case .PositiveNoun:
            return "positive_noun"
        case .SecondPerson:
            return "second_person"
        case .SecondPersonPossessive:
            return "second_person_possessive"
        case .SecondPersonReflexive:
            return "second_person_reflexive"
        case .ThirdPersonPossessive:
            return "third_person_possessive"
        case .Multiple(_):
            return ""
        }
    }
    
    var words: [String] {
        if case .Multiple(let searchingWords) = self {
            return searchingWords.map { $0.words }.reduce([], combine: +)
        }
        if let content = wordLists[wordListPath] {
            return content
        }
        let bundle = NSBundle(forClass: Tokenizer.self)
        let path = bundle.pathForResource(wordListPath, ofType: "wordlist")!
        let input = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
        let list = input.componentsSeparatedByString("\n").filter { $0.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 }
        wordLists[wordListPath] = list
        return list
    }
    
    var regexPattern: String {
        return "\\b(\(words.joinWithSeparator("|")))\\b"
    }
    
    var regexPatternWithNoWordBoundaries: String {
        return "(\(words.joinWithSeparator("|")))"
    }
}
