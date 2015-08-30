//
//  SwiftParsingEngineTests.swift
//  SwiftParsingEngineTests
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/30.
//  Copyright © 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import XCTest
@testable import SwiftParsingEngine

let NL = "\n"
class SwiftParsingEngineTests: XCTestCase {
    let testedString =
        "`// This is a line comment."+NL
        + "<DOCTYPE! html>"+NL
        + "<html>"+NL
        + "  <head>"+NL
        + "    <meta charset=\"UTF-8\">"+NL
        + "  </head>"+NL
        + "  <body>"+NL
        + "    <table>"+NL
        + "    `for row in rows {"+NL
        + "      <tr>"+NL
        + "        <td`if row.img == nil {:colspan=\"2\"}>"+NL
        + "          `row.title"+NL
        + "        </td>"+NL
        + "        `row.img.enclose{"+NL
        + "        <td>"+NL
        + "          <img src=\"/img/`$0\">"+NL
        + "        </td>}"+NL
        + "      </tr>"+NL
        + "    }"+NL
        + "    </table>"+NL
        + "  </body>"+NL
        + "</html>"+NL
    var tokenizer: Tokenizer!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        tokenizer = Tokenizer(string: testedString, syntax: lexicalSyntax)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTokenizer1() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        do {
        let token1 = try tokenizer.getToken()
        var string = token1.string
        print(string.debugDescription)
        XCTAssert(token1 is NewLine && string.hasPrefix("//") && string.hasSuffix(".\n"))
        
        let token2 = try tokenizer.getToken()
        string = token2.string
        print(string.debugDescription)
        XCTAssert(token2 is HTMLTextToken && string.hasPrefix("<D") && string.hasSuffix("  "))
        
        let token3 = try tokenizer.getToken()
        string = token3.string
        print(string.debugDescription)
        XCTAssert(token3 is ForToken && string == "for")
        
        tokenizer.currentState = .Expression
        
        let token4 = try tokenizer.getToken()
        string = token4.string
        print(string.debugDescription)
        XCTAssert(token4 is WhiteSpace && string == " ")
        
        let token5 = try tokenizer.getToken()
        string = token5.string
        print(string.debugDescription)
        XCTAssert(token5 is IdentifierToken && string == "row")
        
        let token6 = try tokenizer.getToken()
        string = token6.string
        print(string.debugDescription)
        XCTAssert(token6 is WhiteSpace && string == " ")
        
        let token7 = try tokenizer.getToken()
        string = token7.string
        print(string.debugDescription)
        XCTAssert(token7 is InToken && string == "in")
        
        let token8 = try tokenizer.getToken()
        string = token8.string
        print(string.debugDescription)
        XCTAssert(token8 is WhiteSpace && string == " ")
        
        let token9 = try tokenizer.getToken()
        string = token9.string
        print(string.debugDescription)
        XCTAssert(token9 is IdentifierToken && string == "rows")
        
        let token10 = try tokenizer.getToken()
        string = token10.string
        print(string.debugDescription)
        XCTAssert(token10 is WhiteSpace && string == " ")
        
        let token11 = try tokenizer.getToken()
        string = token11.string
        print(string.debugDescription)
        XCTAssert(token11 is LeftBrace && string == "{")
        
        tokenizer.currentState = .Block
        
        let token12 = try tokenizer.getToken()
        string = token12.string
        print(string.debugDescription)
        XCTAssert(token12 is NewLine && string == "\n")
        
        let token13 = try tokenizer.getToken()
        string = token13.string
        print(string.debugDescription)
        XCTAssert(token13 is WhiteSpace && string == "      ")
        
        let token14 = try tokenizer.getToken()
        string = token14.string
        print(string.debugDescription)
        XCTAssert(token14 is TagOpener && string == "tr")
        
        tokenizer.currentState = .TagEscape
        
        let token15 = try tokenizer.getToken()
        string = token15.string
        print(string.debugDescription)
        XCTAssert(token15 is HTMLTextToken && string.hasPrefix(">\n") && string.hasSuffix("  "))
        
        let token15_1 = try tokenizer.getToken()
        string = token15_1.string
        print(string.debugDescription)
        XCTAssert(token15_1 is TagOpener && string == "td")
        
        let token16 = try tokenizer.getToken()
        string = token16.string
        print(string.debugDescription)
        XCTAssert(token16 is IfToken && string == "if")
        
        tokenizer.currentState = .Expression
        
        let token17 = try tokenizer.getToken()
        string = token17.string
        print(string.debugDescription)
        XCTAssert(token17 is WhiteSpace && string == " ")
        
        let token18 = try tokenizer.getToken()
        string = token18.string
        print(string.debugDescription)
        XCTAssert(token18 is IdentifierToken && string == "row")
        
        let token19 = try tokenizer.getToken()
        string = token19.string
        print(string.debugDescription)
        XCTAssert(token19 is DotToken && string == ".")
        
        let token20 = try tokenizer.getToken()
        string = token20.string
        print(string.debugDescription)
        XCTAssert(token20 is IdentifierToken && string == "img")
        
        let token21 = try tokenizer.getToken()
        string = token21.string
        print(string.debugDescription)
        XCTAssert(token21 is WhiteSpace && string == " ")
        
        let token22 = try tokenizer.getToken()
        string = token22.string
        print(string.debugDescription)
        XCTAssert(token22 is OperatorToken && string == "==")
        
        let token23 = try tokenizer.getToken()
        string = token23.string
        print(string.debugDescription)
        XCTAssert(token23 is WhiteSpace && string == " ")
        
        let token24 = try tokenizer.getToken()
        string = token24.string
        print(string.debugDescription)
        XCTAssert(token24 is NilToken && string == "nil")
            
            let token25 = try tokenizer.getToken()
            string = token25.string
            print(string.debugDescription)
            XCTAssert(token25 is WhiteSpace && string == " ")
            
            let token26 = try tokenizer.getToken()
            string = token26.string
            print(string.debugDescription)
            XCTAssert(token26 is InlineLeader && string == "{:")
            
            tokenizer.currentState = .Inline
            
            let token27 = try tokenizer.getToken()
            string = token27.string
            print(string.debugDescription)
            XCTAssert(token27 is HTMLTextToken && string.hasPrefix("co") && string.hasSuffix("2\""))
            
            let token28 = try tokenizer.getToken()
            string = token28.string
            print(string.debugDescription)
            XCTAssert(token28 is RightBrace && string == "}")
            
            tokenizer.currentState = .TagEscape
            
            let token29 = try tokenizer.getToken()
            string = token29.string
            print(string.debugDescription)
            XCTAssert(token29 is HTMLTextToken && string.hasPrefix(">\n") && string.hasSuffix("  "))
            
            let token30 = try tokenizer.getToken()
            string = token30.string
            print(string.debugDescription)
            XCTAssert(token30 is IdentifierToken && string == "row")
            
            tokenizer.currentState = .Simple
//            
//            let token31 = try tokenizer.getToken()
//            string = token31.string
//            print(string.debugDescription)
//            XCTAssert(token31 is DotToken && string == ".")
            
            let token32 = try tokenizer.getToken()
            string = token32.string
            print(string.debugDescription)
            XCTAssert(token32 is IdentifierToken && string == "title")
            
            let token33 = try tokenizer.getToken()
            string = token33.string
            print(string.debugDescription)
            XCTAssert(token33 is HTMLTextToken && string.hasPrefix("\n ") && string.hasSuffix("  "))
            
            tokenizer.currentState = .TagEscape
            
            let token34 = try tokenizer.getToken()
            string = token34.string
            print(string.debugDescription)
            XCTAssert(token34 is ClosingTag && string == "td")
            
            let token34_1 = try tokenizer.getToken()
            string = token34_1.string
            print(string.debugDescription)
            XCTAssert(token34_1 is HTMLTextToken && string.hasPrefix("\n ") && string.hasSuffix("  "))
            
            let token35 = try tokenizer.getToken()
            string = token35.string
            print(string.debugDescription)
            XCTAssert(token35 is IdentifierToken && string == "row")
            
            tokenizer.currentState = .Simple
//            
//            let token36 = try tokenizer.getToken()
//            string = token36.string
//            print(string.debugDescription)
//            XCTAssert(token36 is DotToken && string == ".")
            
            let token37 = try tokenizer.getToken()
            string = token37.string
            print(string.debugDescription)
            XCTAssert(token37 is IdentifierToken && string == "img")
//            
//            let token38 = try tokenizer.getToken()
//            string = token38.string
//            print(string.debugDescription)
//            XCTAssert(token38 is DotToken && string == ".")
            
            let token39 = try tokenizer.getToken()
            string = token39.string
            print(string.debugDescription)
            XCTAssert(token39 is IdentifierToken && string == "enclose")
            
            let token40 = try tokenizer.getToken()
            string = token40.string
            print(string.debugDescription)
            XCTAssert(token40 is LeftBrace && string == "{")
            
            tokenizer.currentState = .Block
            
            let token41 = try tokenizer.getToken()
            string = token41.string
            print(string.debugDescription)
            XCTAssert(token41 is NewLine && string == "\n")
            
            let token42 = try tokenizer.getToken()
            string = token42.string
            print(string.debugDescription)
            XCTAssert(token42 is WhiteSpace && string == "        ")
            
            let token43 = try tokenizer.getToken()
            string = token43.string
            print(string.debugDescription)
            XCTAssert(token43 is TagOpener && string == "td")
            
            tokenizer.currentState = .TagEscape
            
            let token44 = try tokenizer.getToken()
            string = token44.string
            print(string.debugDescription)
            XCTAssert(token44 is HTMLTextToken && string.hasPrefix(">\n") && string.hasSuffix("  "))
            
            let token45 = try tokenizer.getToken()
            string = token45.string
            print(string.debugDescription)
            XCTAssert(token45 is TagOpener && string == "img")
            
            let token46 = try tokenizer.getToken()
            string = token46.string
            print(string.debugDescription)
            XCTAssert(token46 is HTMLTextToken && string.hasPrefix(" s") && string.hasSuffix("g/"))
            
            let token47 = try tokenizer.getToken()
            string = token47.string
            print(string.debugDescription)
            XCTAssert(token47 is IdentifierToken && string == "$0")
            
            tokenizer.currentState = .Simple
            
            let token48 = try tokenizer.getToken()
            string = token48.string
            print(string.debugDescription)
            XCTAssert(token48 is HTMLTextToken && string == "\">")
            
            tokenizer.currentState = .TagEscape
            
            let token49 = try tokenizer.getToken()
            string = token49.string
            print(string.debugDescription)
            XCTAssert(token49 is HTMLTextToken && string.hasPrefix("\n ") && string.hasSuffix("  "))
            
            let token50 = try tokenizer.getToken()
            string = token50.string
            print(string.debugDescription)
            XCTAssert(token50 is ClosingTag && string == "td")
            
            tokenizer.currentState = .Block
            
            let token51 = try tokenizer.getToken()
            string = token51.string
            print(string.debugDescription)
            XCTAssert(token51 is RightBrace && string == "}")
            
            tokenizer.currentState = .Simple
            
            let token52 = try tokenizer.getToken()
            string = token52.string
            print(string.debugDescription)
            XCTAssert(token52 is HTMLTextToken && string.hasPrefix("\n ") && string.hasSuffix("  "))
            
            tokenizer.currentState = .TagEscape
            
            let token53 = try tokenizer.getToken()
            string = token53.string
            print(string.debugDescription)
            XCTAssert(token53 is ClosingTag && string == "tr")
            
            tokenizer.currentState = .Block
            
            let token54 = try tokenizer.getToken()
            string = token54.string
            print(string.debugDescription)
            XCTAssert(token54 is NewLine && string == "\n")
            
            let token55 = try tokenizer.getToken()
            string = token55.string
            print(string.debugDescription)
            XCTAssert(token55 is WhiteSpace && string == "    ")
            
            let token56 = try tokenizer.getToken()
            string = token56.string
            print(string.debugDescription)
            XCTAssert(token56 is RightBrace && string == "}")
            
            tokenizer.currentState = .HTML
            
            let token57 = try tokenizer.getToken()
            string = token57.string
            print(string.debugDescription)
            XCTAssert(token57 is HTMLTextToken && string.hasPrefix("\n ") && string.hasSuffix(">\n"))
            
            let token58 = try tokenizer.getToken()
            string = token58.string
            print(string.debugDescription)
            XCTAssert(token58 is EndToken && string == "")
            
        } catch let error as TokenizerError {
            print(error)
            XCTFail()
        } catch _ {
            fatalError()
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
