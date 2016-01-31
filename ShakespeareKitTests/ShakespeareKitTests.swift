//
//  ShakespeareKitTests.swift
//  ShakespeareKitTests
//
//  Created by Sihao Lu on 1/22/16.
//  Copyright © 2016 Sihao Lu. All rights reserved.
//

import ShakespeareKit
import XCTest

class ShakespeareKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func readInputFromSourceFileNamed(name: String, suffix: String = "spl") -> String {
        let bundle = NSBundle(forClass: self.dynamicType)
        let path = bundle.pathForResource(name, ofType: suffix)!
        return try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
    }
    
    func testTokenizerWithHelloWorld() {
        verifyTokenizerAgainstSourceFile("HelloWorld")
    }
    
    func testTokenizerWithPrimes() {
        verifyTokenizerAgainstSourceFile("Primes")
    }
    
    func testTokenizerWithReverse() {
        verifyTokenizerAgainstSourceFile("Reverse")
    }
    
    func testParserWithHelloWorld() {
        verifyParserAgainstParsedFile("HelloWorld")
    }
    
    func testParserWithPrimes() {
        verifyParserAgainstParsedFile("Primes")
    }
    
    func testFlightHelloWorld() {
        let input = readInputFromSourceFileNamed("HelloWorld")
        let parser = Parser(input: input)
        do {
            let nodes = try parser.parse()
            Simulator().runNodes(nodes)
        } catch {
            print(error)
        }
    }
    
    func testFlightPrimes() {
        let input = readInputFromSourceFileNamed("Primes")
        let parser = Parser(input: input)
        do {
            let nodes = try parser.parse()
            let sim = Simulator(numberProvider: { () -> Int in
                return 13
            }, characterProvider: { () -> Character in
                return Character(UnicodeScalar(13))
            })
            sim.runNodes(nodes)
        } catch {
            print(error)
        }
    }
    
    func verifyTokenizerAgainstSourceFile(file: String, debug: Bool = false) {
        let input = readInputFromSourceFileNamed(file)
        let expectationFile = readInputFromSourceFileNamed(file, suffix: "tokenized")
        let expectations = expectationFile.componentsSeparatedByString("\n")
        for (i, token) in Tokenizer.tokenize(input).enumerate() {
            if debug {
                print(token)
            } else {
                if expectations.count <= i {
                    XCTFail("Token \(i) \(token) not found in expectations")
                    continue
                }
                if (String(token) != expectations[i]) {
                    XCTFail("Token \(i) \(token) is not the same as expected \(expectations[i])")
                }
            }
        }
    }
    
    func verifyParserAgainstParsedFile(file: String) {
        let input = readInputFromSourceFileNamed(file)
        let expectationFile = readInputFromSourceFileNamed(file, suffix: "parsed")
        let expectations = expectationFile.componentsSeparatedByString("\n")
        let parser = Parser(input: input)
        do {
            for (i, node) in try parser.parse().enumerate() {
                if expectations.count <= i {
                    XCTFail("Node \(i) \(node) not found in expectations")
                    continue
                }
                if (String(node) != expectations[i]) {
                    XCTFail("Node \(i) \(node) is not the same as expected \(expectations[i])")
                }
            }
        } catch {
            
        }
    }
}
