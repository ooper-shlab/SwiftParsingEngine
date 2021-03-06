//
//  SwiftParsingEngineTests.swift
//  SwiftParsingEngineTests
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/30.
//  Copyright © 2015-2017 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import XCTest
@testable import SwiftParsingEngine

class SwiftParsingEngineTests: XCTestCase {
    let testedString = """
        `// This is a line comment.
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset=\"UTF-8\">
          </head>
          <body>
            <table>
            `for row in rows {
              <tr>
                <td`if row.img == nil {: colspan=\"2\"}>
                  `row.title
                </td>
                `row.img.enclose{
                <td>
                  <img src=\"/img/`$0\">
                </td>}
              </tr>
            }
            </table>
          </body>
        </html>

        """
    var tokenizer: Tokenizer!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        tokenizer = Tokenizer(string: testedString)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTokenizer1() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        do {
            let token1 = try tokenizer.getToken(.Initial)
            var string = token1.string
            print(string.debugDescription)
            XCTAssert(token1 is NewLine && string == "\n")
            
            let token2 = try tokenizer.getToken(.Initial)
            string = token2.string
            print(string.debugDescription)
            XCTAssert(token2 is HTMLTextToken && string.hasPrefix("<!") && string.hasSuffix("  "))
            
            let token3 = try tokenizer.getToken(.Initial)
            string = token3.string
            print(string.debugDescription)
            XCTAssert(token3 is ForToken && string == "for")
            
            let token4 = try tokenizer.getToken(.Expression)
            string = token4.string
            print(string.debugDescription)
            XCTAssert(token4 is WhiteSpace && string == " ")
            
            let token5 = try tokenizer.getToken(.Expression)
            string = token5.string
            print(string.debugDescription)
            XCTAssert(token5 is IdentifierToken && string == "row")
            
            let token6 = try tokenizer.getToken(.Expression)
            string = token6.string
            print(string.debugDescription)
            XCTAssert(token6 is WhiteSpace && string == " ")
            
            let token7 = try tokenizer.getToken(.Expression)
            string = token7.string
            print(string.debugDescription)
            XCTAssert(token7 is InToken && string == "in")
            
            let token8 = try tokenizer.getToken(.Expression)
            string = token8.string
            print(string.debugDescription)
            XCTAssert(token8 is WhiteSpace && string == " ")
            
            let token9 = try tokenizer.getToken(.Expression)
            string = token9.string
            print(string.debugDescription)
            XCTAssert(token9 is IdentifierToken && string == "rows")
            
            let token10 = try tokenizer.getToken(.Expression)
            string = token10.string
            print(string.debugDescription)
            XCTAssert(token10 is WhiteSpace && string == " ")
            
            let token11 = try tokenizer.getToken(.Expression)
            string = token11.string
            print(string.debugDescription)
            XCTAssert(token11 is LeftBrace && string == "{")
            
            let token12 = try tokenizer.getToken(.Block)
            string = token12.string
            print(string.debugDescription)
            XCTAssert(token12 is NewLine && string == "\n")
            
            let token13 = try tokenizer.getToken(.Block)
            string = token13.string
            print(string.debugDescription)
            XCTAssert(token13 is WhiteSpace && string == "      ")
            
            let token14 = try tokenizer.getToken(.Block)
            string = token14.string
            print(string.debugDescription)
            XCTAssert(token14 is TagOpener && string == "<tr")
            
            let token15 = try tokenizer.getToken(.TagEscape)
            string = token15.string
            print(string.debugDescription)
            XCTAssert(token15 is HTMLTextToken && string.hasPrefix(">\n") && string.hasSuffix("  "))
            
            let token15_1 = try tokenizer.getToken(.TagEscape)
            string = token15_1.string
            print(string.debugDescription)
            XCTAssert(token15_1 is TagOpener && string == "<td")
            
            let token16 = try tokenizer.getToken(.TagEscape)
            string = token16.string
            print(string.debugDescription)
            XCTAssert(token16 is IfToken && string == "if")
            
            let token17 = try tokenizer.getToken(.Expression)
            string = token17.string
            print(string.debugDescription)
            XCTAssert(token17 is WhiteSpace && string == " ")
            
            let token18 = try tokenizer.getToken(.Expression)
            string = token18.string
            print(string.debugDescription)
            XCTAssert(token18 is IdentifierToken && string == "row")
            
            let token19 = try tokenizer.getToken(.Expression)
            string = token19.string
            print(string.debugDescription)
            XCTAssert(token19 is DotToken && string == ".")
            
            let token20 = try tokenizer.getToken(.Expression)
            string = token20.string
            print(string.debugDescription)
            XCTAssert(token20 is IdentifierToken && string == "img")
            
            let token21 = try tokenizer.getToken(.Expression)
            string = token21.string
            print(string.debugDescription)
            XCTAssert(token21 is WhiteSpace && string == " ")
            
            let token22 = try tokenizer.getToken(.Expression)
            string = token22.string
            print(string.debugDescription)
            XCTAssert(token22 is OperatorToken && string == "==")
            
            let token23 = try tokenizer.getToken(.Expression)
            string = token23.string
            print(string.debugDescription)
            XCTAssert(token23 is WhiteSpace && string == " ")
            
            let token24 = try tokenizer.getToken(.Expression)
            string = token24.string
            print(string.debugDescription)
            XCTAssert(token24 is NilToken && string == "nil")
            
            let token25 = try tokenizer.getToken(.Expression)
            string = token25.string
            print(string.debugDescription)
            XCTAssert(token25 is WhiteSpace && string == " ")
            
            let token26 = try tokenizer.getToken(.Expression)
            string = token26.string
            print(string.debugDescription)
            XCTAssert(token26 is InlineLeader && string == "{:")
            
            let token27 = try tokenizer.getToken(.Inline)
            string = token27.string
            print(string.debugDescription)
            XCTAssert(token27 is HTMLTextToken && string.hasPrefix(" c") && string.hasSuffix("2\""))
            
            let token28 = try tokenizer.getToken(.Inline)
            string = token28.string
            print(string.debugDescription)
            XCTAssert(token28 is RightBrace && string == "}")
            
            let token29 = try tokenizer.getToken(.TagEscape)
            string = token29.string
            print(string.debugDescription)
            XCTAssert(token29 is HTMLTextToken && string.hasPrefix(">\n") && string.hasSuffix("  "))
            
            let token30 = try tokenizer.getToken(.TagEscape)
            string = token30.string
            print(string.debugDescription)
            XCTAssert(token30 is IdentifierToken && string == "row")
            
            let token31a = try tokenizer.getToken(.Simple)
            string = token31a.string
            print(string.debugDescription)
            XCTAssert(token31a is DotToken && string == ".")
            
            let token31 = try tokenizer.getToken(.Simple)
            string = token31.string
            print(string.debugDescription)
            XCTAssert(token31 is IdentifierToken && string == "title")
            
            let token32 = try tokenizer.getToken(.TagEscape)
            string = token32.string
            print(string.debugDescription)
            XCTAssert(token32 is HTMLTextToken && string.hasPrefix("\n ") && string.hasSuffix("  "))
            
            let token33 = try tokenizer.getToken(.TagEscape)
            string = token33.string
            print(string.debugDescription)
            XCTAssert(token33 is ClosingTag && string == "</td")
            
            let token34 = try tokenizer.getToken(.TagEscape)
            string = token34.string
            print(string.debugDescription)
            XCTAssert(token34 is HTMLTextToken && string.hasPrefix("\n ") && string.hasSuffix("  "))
            
            let token35 = try tokenizer.getToken(.TagEscape)
            string = token35.string
            print(string.debugDescription)
            XCTAssert(token35 is IdentifierToken && string == "row")
            
            let token36 = try tokenizer.getToken(.Simple)
            string = token36.string
            print(string.debugDescription)
            XCTAssert(token36 is DotToken && string == ".")
            
            let token37 = try tokenizer.getToken(.Simple)
            string = token37.string
            print(string.debugDescription)
            XCTAssert(token37 is IdentifierToken && string == "img")
            
            let token38 = try tokenizer.getToken(.Simple)
            string = token38.string
            print(string.debugDescription)
            XCTAssert(token38 is DotToken && string == ".")
            
            let token39 = try tokenizer.getToken(.Simple)
            string = token39.string
            print(string.debugDescription)
            XCTAssert(token39 is IdentifierToken && string == "enclose")
            
            let token40 = try tokenizer.getToken(.Simple)
            string = token40.string
            print(string.debugDescription)
            XCTAssert(token40 is LeftBrace && string == "{")
            
            let token41 = try tokenizer.getToken(.Block)
            string = token41.string
            print(string.debugDescription)
            XCTAssert(token41 is NewLine && string == "\n")
            
            let token42 = try tokenizer.getToken(.Block)
            string = token42.string
            print(string.debugDescription)
            XCTAssert(token42 is WhiteSpace && string == "        ")
            
            let token43 = try tokenizer.getToken(.Block)
            string = token43.string
            print(string.debugDescription)
            XCTAssert(token43 is TagOpener && string == "<td")
            
            let token44 = try tokenizer.getToken(.TagEscape)
            string = token44.string
            print(string.debugDescription)
            XCTAssert(token44 is HTMLTextToken && string.hasPrefix(">\n") && string.hasSuffix("  "))
            
            let token45 = try tokenizer.getToken(.TagEscape)
            string = token45.string
            print(string.debugDescription)
            XCTAssert(token45 is TagOpener && string == "<img")
            
            let token46 = try tokenizer.getToken(.TagEscape)
            string = token46.string
            print(string.debugDescription)
            XCTAssert(token46 is HTMLTextToken && string.hasPrefix(" s") && string.hasSuffix("g/"))
            
            let token47 = try tokenizer.getToken(.TagEscape)
            string = token47.string
            print(string.debugDescription)
            XCTAssert(token47 is IdentifierToken && string == "$0")
            
            let token48 = try tokenizer.getToken(.TagEscape)
            string = token48.string
            print(string.debugDescription)
            XCTAssert(token48 is HTMLTextToken && string.hasPrefix("\">") && string.hasSuffix("  "))
            
            let token50 = try tokenizer.getToken(.TagEscape)
            string = token50.string
            print(string.debugDescription)
            XCTAssert(token50 is ClosingTag && string == "</td")
            
            let token51 = try tokenizer.getToken(.Block)
            string = token51.string
            print(string.debugDescription)
            XCTAssert(token51 is RightBrace && string == "}")
            
            let token52 = try tokenizer.getToken(.TagEscape)
            string = token52.string
            print(string.debugDescription)
            XCTAssert(token52 is HTMLTextToken && string.hasPrefix("\n ") && string.hasSuffix("  "))
            
            let token53 = try tokenizer.getToken(.TagEscape)
            string = token53.string
            print(string.debugDescription)
            XCTAssert(token53 is ClosingTag && string == "</tr")
            
            let token54 = try tokenizer.getToken(.Block)
            string = token54.string
            print(string.debugDescription)
            XCTAssert(token54 is NewLine && string == "\n")
            
            let token55 = try tokenizer.getToken(.Block)
            string = token55.string
            print(string.debugDescription)
            XCTAssert(token55 is WhiteSpace && string == "    ")
            
            let token56 = try tokenizer.getToken(.Block)
            string = token56.string
            print(string.debugDescription)
            XCTAssert(token56 is RightBrace && string == "}")
            
            let token57 = try tokenizer.getToken(.HTML)
            string = token57.string
            print(string.debugDescription)
            XCTAssert(token57 is HTMLTextToken && string.hasPrefix("\n ") && string.hasSuffix(">\n"))
            
            let token58 = try tokenizer.getToken(.HTML)
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
    
    func testParser1() {
        let parser = Parser(tokenizer: tokenizer)
        var matches = parser.HTMLOutputStatement.match(parser)
        let string = (matches[0].nodes[0] as! HTMLOutputNode).text
        print(string.debugDescription)
        XCTAssert(matches.count == 1 && string.hasPrefix("<!") && string.hasSuffix("  "))
    }
    
    func testParser1a() {
        let parser = Parser(tokenizer: tokenizer)
        let result = parser.parse(parser.Template)
        XCTAssert(result != nil)
    }
    
    func testParser1b() {
        let str = """
                `for row in rows {
                  <tr>
                    <td`if row.img == nil {: colspan=\"2\"}>
                      `row.title
                    </td>
                    `row.img.enclose{
                    <td>
                      <img src=\"/img/`$0\">
                    </td>}
                  </tr>
                }
                """
        let tk = Tokenizer(string: str)
        let ps = Parser(tokenizer: tk)
        let result = ps.parse(ps.Template)
        XCTAssert(result != nil)
    }
    
    let simpleTestedString = """
    var x = 0
    if x == 0 {print('')}
    """

    func testTokenizer2() {
        let st = SimpleTokenizer(string: simpleTestedString)
        do {
            let t1 = try st.getToken(.Initial)
            XCTAssert(t1 is SimpleIdentifierToken && t1.string == "var")
            let t2 = try st.getToken(.Initial)
            XCTAssert(t2 is SimpleIdentifierToken && t2.string == "x")
            let t3 = try st.getToken(.Initial)
            XCTAssert(t3 is SimpleSymbolToken && t3.string == "=")
            let t4 = try st.getToken(.Initial)
            XCTAssert(t4 is SimpleNumericLiteralToken && t4.string == "0")
            let t5 = try st.getToken(.Initial)
            XCTAssert(t5 is SimpleNewlineToken && t5.string == "\n")
            let t6 = try st.getToken(.Initial)
            XCTAssert(t6 is SimpleIdentifierToken && t6.string == "if")
            let t7 = try st.getToken(.Initial)
            XCTAssert(t7 is SimpleIdentifierToken && t7.string == "x")
            let t8 = try st.getToken(.Initial)
            XCTAssert(t8 is SimpleOperatorToken && t8.string == "==")
            let t9 = try st.getToken(.Initial)
            XCTAssert(t9 is SimpleNumericLiteralToken && t9.string == "0")
            let t10 = try st.getToken(.Initial)
            XCTAssert(t10 is SimpleSymbolToken && t10.string == "{")
            let t11 = try st.getToken(.Initial)
            XCTAssert(t11 is SimpleIdentifierToken && t11.string == "print")
            let t12 = try st.getToken(.Initial)
            XCTAssert(t12 is SimpleSymbolToken && t12.string == "(")
            let t13 = try st.getToken(.Initial)
            XCTAssert(t13 is SimpleStringLiteralToken && t13.string == "''")
            let t14 = try st.getToken(.Initial)
            XCTAssert(t14 is SimpleSymbolToken && t14.string == ")")
            let t15 = try st.getToken(.Initial)
            XCTAssert(t15 is SimpleSymbolToken && t15.string == "}")
            let t16 = try st.getToken(.Initial)
            XCTAssert(t16 is EndToken)
        } catch let error as TokenizerError {
            print(error)
            XCTFail()
        } catch _ {
            fatalError()
        }
    }
    
    func testParser2() {
        let st = SimpleTokenizer(string: simpleTestedString)
        let parser = SimpleParser(tokenizer: st)
        if let node = parser.parse(parser.SimpleScript) as? SimpleScriptNode {
            debugPrint(node)
            XCTAssert(node.debugDescription == "var `x` = 0.0;if( (x)==(0.0) ) {(print)(\"\")}")
        } else {
            XCTFail()
        }
    }
    
    func testPerformanceParser2() {
        // This is an example of a performance test case.
        let st = SimpleTokenizer(string: simpleTestedString)
        let parser = SimpleParser(tokenizer: st)
        self.measure {
            // Put the code you want to measure the time of here.
            parser.reset()
            _ = parser.parse(parser.SimpleScript)
        }
    }
}
