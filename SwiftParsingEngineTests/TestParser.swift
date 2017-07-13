//
//  Parser.swift
//  SwiftParsingEngine
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/8/23.
//  Copyright (c) 2015-2017 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation
import SwiftParsingEngine

struct ParsingState: StackableParsingState {
    typealias ExtraInfoType = String
    var context: LexicalContext
    var matchingTag: String = ""
    var contextStack: [(LexicalContext, String)] = []
    var currentPosition: Int
    //var tagName: String
    init() {
        context = LexicalContext.Initial
        contextStack = []
        currentPosition = 0
        //tagName = String()
    }
    mutating func pushAndSet(_ newContext: LexicalContext) {
        contextStack.append((context, matchingTag))
        context = newContext
        matchingTag = ""
    }
    mutating func pushAndSet(_ newContext: LexicalContext, newExtraInfo: String?) {
        contextStack.append((context, matchingTag))
        context = newContext
        matchingTag = newExtraInfo ?? ""
    }
    mutating func pop() {
        let contextInfo = contextStack.popLast()!
        self.context = contextInfo.0
        self.matchingTag = contextInfo.1
    }
}

typealias NonTerminal = NonTerminalBase<ParsingState>

typealias Terminal = TerminalBase<ParsingState>

class TagStartClass: Terminal {
    override init(_ type: Token.Type) {
        super.init(type)
    }
    
    override func match(_ parser: ParserBase<ParsingState>) -> [SyntaxMatch<ParsingState>] {
            let savedState = parser.state
            var result: [SyntaxMatch<ParsingState>] = []
            //print("matching to \(self.type!)")
            if let token = (try? parser.tokenizer.getToken(parser.state.context)) as? TagOpener {
                //print("matching \(token.string.debugDescription) to \(self.type!)")
                let nodes: [NodeBase] = [TerminalNode(token: token)]
                parser.state.pushAndSet(.TagEscape, newExtraInfo: token.tagName)
                result = [SyntaxMatch(pattern: self, nodes: nodes, state: parser.state)]
                //print("TagStartClass-->succeeded \(token.string.debugDescription)")
                return result
            } else {
                //print("TagStartClass-->failed")
            }
            parser.state = savedState
            return result
    }
}

class NestedTagStartClass: Terminal {
    override init(_ type: Token.Type) {
        super.init(type)
    }
    
    override func match(_ parser: ParserBase<ParsingState>) -> [SyntaxMatch<ParsingState>] {
        let savedState = parser.state
        var result: [SyntaxMatch<ParsingState>] = []
        //print("matching to \(self.type!)")
        if let token = (try? parser.tokenizer.getToken(parser.state.context)) as? TagOpener, token.tagName == parser.state.matchingTag {
            //print("matching \(token.string.debugDescription) to \(self.type!)")
            let nodes: [NodeBase] = [TerminalNode(token: token)]
            parser.state.pushAndSet(.TagEscape, newExtraInfo: token.tagName)
            result = [SyntaxMatch(pattern: self, nodes: nodes, state: parser.state)]
            //print("TagStartClass-->succeeded \(token.string.debugDescription)")
            return result
        } else {
            //print("TagStartClass-->failed")
        }
        parser.state = savedState
        return result
    }
}

class TagEndClass: Terminal {
    override init(_ type: Token.Type) {
        super.init(type)
    }
    
    override func match(_ parser: ParserBase<ParsingState>) -> [SyntaxMatch<ParsingState>] {
        let savedState = parser.state
        var result: [SyntaxMatch<ParsingState>] = []
        //print("matching to \(self.type!) in \(parser.state.matchingTag)")
        if let token = (try? parser.tokenizer.getToken(parser.state.context)) as? ClosingTag, token.tagName == parser.state.matchingTag {
            //print("matching \(token.string.debugDescription) to \(self.type!)")
            let nodes: [NodeBase] = [TerminalNode(token: token)]
            parser.state.pop()
            result = [SyntaxMatch(pattern: self, nodes: nodes, state: parser.state)]
            //print("TagEndClass-->succeeded \(token.string.debugDescription)")
            return result
        } else {
            //print("TagEndClass-->failed")
        }
        parser.state = savedState
        return result
    }
}

class Parser: ParserBase<ParsingState> {
    
    //MARK: Non terminal symbols
    let Template = NonTerminal("Template"){_ in RootNode()}
    
    //Expression
    let Expression = NonTerminal("Expression")
    let PrefixExpression = NonTerminal("PrefixExpression")
    let InOutExpression = NonTerminal("InOutExpression")
    let PostfixExpression = NonTerminal("PostfixExpression")
    let BinaryExpression = NonTerminal("BinaryExpression")
    let PostfixTail = NonTerminal("PostfixTail"){_ in BinaryTailNode()}
    let FunctionCallTail = NonTerminal("FunctionCallTail"){_ in BinaryTailNode()}
    let InitializerTail = NonTerminal("InitializerTail"){_ in BinaryTailNode()}
    let ExplicitMemberTail = NonTerminal("ExplicitMemberTail"){_ in BinaryTailNode()}
    let PostfixSelfTail = NonTerminal("PostfixSelfTail"){_ in BinaryTailNode()}
    let DynamicTypeTail = NonTerminal("DynamicTypeTail"){_ in BinaryTailNode()}
    let SubscriptTail = NonTerminal("SubscriptTail"){_ in BinaryTailNode()}
    let ForcedValueTail = NonTerminal("ForcedValueTail"){_ in BinaryTailNode()}
    let OptionalChainingTail = NonTerminal("OptionalChainingTail"){_ in BinaryTailNode()}
    let PrimaryExpression = NonTerminal("PrimaryExpression"){_ in ExpressionNode()}
    let ParenthesizedExpression = NonTerminal("ParenthesizedExpression"){_ in ExpressionNode()}
    let TrailingClosure = NonTerminal("TrailingClosure"){_ in BlockNode()}
    let ClosureExpression = NonTerminal("ClosureExpression"){_ in BlockNode()}
    let IfStatement = NonTerminal("IfStatement"){_ in IfStatementNode()}
    let ForStatement = NonTerminal("ForStatement"){_ in ForStatementNode()}
    let ForInStatement = NonTerminal("ForInStatement"){_ in ForStatementNode()}
    let GenericArgumentClause = NonTerminal("GenericArgumentClause"){_ in BlockNode()}
    let HTMLOutputStatement = NonTerminal("HTMLOutputStatement"){match in HTMLOutputNode.createNode(match.nodes)}
    let LiteralExpression = NonTerminal("LiteralExpression"){_ in ExpressionNode()}
    let SelfExpression = NonTerminal("SelfExpression"){_ in ExpressionNode()}
    let SuperclassExpression = NonTerminal("SuperclassExpression"){_ in ExpressionNode()}
    let ImplicitMemberExpression = NonTerminal("ImplicitMemberExpression"){_ in ExpressionNode()}
    let WildcardExpression = NonTerminal("WildcardExpression"){_ in ExpressionNode()}
    let ExpressionList = NonTerminal("ExpressionList"){_ in BlockNode()}
    let ClosureSignature = NonTerminal("ClosureSignature") {_ in BlockNode()}
    let ExpressionElement = NonTerminal("ExpressionElement") {_ in BlockNode()}
    let ForInit = NonTerminal("ForInit"){_ in BlockNode()}
    let CodeBlock = NonTerminal("CodeBlock"){_ in BlockNode()}
    let ConditionClause = NonTerminal("ConditionClause") {_ in ExpressionNode()}
    let ElseClause = NonTerminal("ElseClause") {_ in BlockNode()}
    let VariableDeclarationHead = NonTerminal("VariableDeclarationHead") {_ in BlockNode()}
    let PatternInitializerList = NonTerminal("PatternInitializerList") {_ in BlockNode()}
    let VariableName = NonTerminal("VariableName") {_ in BlockNode()}
    let TypeAnnotation = NonTerminal("TypeAnnotation") {_ in BlockNode()}
    let GetterSetterBlock = NonTerminal("GetterSetterBlock") {_ in BlockNode()}
    let GetterSetterKeywordBlock = NonTerminal("GetterSetterKeywordBlock") {_ in BlockNode()}
    let Initializer = NonTerminal("Initializer") {_ in BlockNode()}
    let WillSetDidSetBlock = NonTerminal("WillSetDidSetBlock") {_ in BlockNode()}
    let Attribute = NonTerminal("Attribute") {_ in BlockNode()}
    let DeclarationModifier = NonTerminal("DeclarationModifier") {_ in BlockNode()}
    let AttributeName = NonTerminal("AttributeName") {_ in BlockNode()}
    let AttributeArgumentClause = NonTerminal("AttributeArgumentClause") {_ in BlockNode()}
    let AccessLevelModifier = NonTerminal("AccessLevelModifier") {_ in BlockNode()}
    let Pattern = NonTerminal("Pattern") {_ in BlockNode()}
    let WhereClause = NonTerminal("WhereClause") {_ in BlockNode()}
    let IdentifierPattern = NonTerminal("IdentifierPattern") {_ in BlockNode()}
    let ValueBindingPattern = NonTerminal("ValueBindingPattern") {_ in BlockNode()}
    let TuplePattern = NonTerminal("TuplePattern") {_ in BlockNode()}
    let EnumCasePattern = NonTerminal("EnumCasePattern") {_ in BlockNode()}
    let OptionalPattern = NonTerminal("OptionalPattern") {_ in BlockNode()}
    let TypeCastingPattern = NonTerminal("TypeCastingPattern") {_ in BlockNode()}
    let ExpressionPattern = NonTerminal("ExpressionPattern") {_ in BlockNode()}
    let TuplePatternElementList = NonTerminal("TuplePatternElementList") {_ in BlockNode()}
    let TuplePatternElement = NonTerminal("TuplePatternElement") {_ in BlockNode()}
    let TypeIdentifier = NonTerminal("TypeIdentifier") {_ in BlockNode()}
    let EnumCaseName = NonTerminal("EnumCaseName") {_ in BlockNode()}
    let TypeName = NonTerminal("TypeName") {_ in BlockNode()}
    let SubPattern = NonTerminal("SubPattern") {_ in BlockNode()}
    let IsPattern = NonTerminal("IsPattern") {_ in BlockNode()}
    let TypeRef = NonTerminal("Type") {_ in BlockNode()}
    //Statement
    let Statement = NonTerminal("Statement"){_ in StatementNode()}
    let LoopStatement = NonTerminal("LoopStatement") {_ in BlockNode()}
    let BranchStatement = NonTerminal("BranchStatement")
    let LabeledStatement = NonTerminal("LabeledStatement")
    let ControlTransferStatement = NonTerminal("ControlTransferStatement")
    let DeferStatement = NonTerminal("DeferStatement")
    let DoStatement = NonTerminal("DoStatement")
    let CompilerControlStatement = NonTerminal("CompilerControlStatement")
    //Declaration
    let Declaration = NonTerminal("Declaration")
    let ImportDeclaration = NonTerminal("ImportDeclaration")
    let ConstantDeclaration = NonTerminal("ConstantDeclaration")
    let VariableDeclaration = NonTerminal("VariableDeclaration")
    let TypealiasDeclaration = NonTerminal("TypealiasDeclaration")
    let FunctionDeclaration = NonTerminal("FunctionDeclaration")
    let EnumDeclaration = NonTerminal("EnumDeclaration")
    let StructDeclaration = NonTerminal("StructDeclaration")
    let ClassDeclaration = NonTerminal("ClassDeclaration")
    let ProtocolDeclaration = NonTerminal("ProtocolDeclaration")
    let InitializerDeclaration = NonTerminal("InitializerDeclaration")
    let DeinitializerDeclaration = NonTerminal("DeinitializerDeclaration")
    let ExtensionDeclaration = NonTerminal("ExtensionDeclaration")
    let SubscriptDeclaration = NonTerminal("SubscriptDeclaration")
    let OperaotrDeclaration = NonTerminal("OperaotrDeclaration")
    //BranchStatement
    let GuardStatement = NonTerminal("GuardStatement")
    let SwitchStatement = NonTerminal("SwitchStatement")
    //ControlTransferStatement
    let BreakStatement = NonTerminal("BreakStatement")
    let ContinueStatement = NonTerminal("ContinueStatement")
    let FallthroughStatement = NonTerminal("FallthroughStatement")
    let ReturnStatement = NonTerminal("ReturnStatement")
    let ThrowStatement = NonTerminal("ThrowStatement")
    //Type
    let ArrayType = NonTerminal("ArrayType")
    let DictionaryType = NonTerminal("DictionaryType")
    let FunctionType = NonTerminal("FunctionType")
    let TupleType = NonTerminal("TupleType")
    let OptionalType = NonTerminal("OptionalType")
    let ImplicitlyUnwrappedOptionalType = NonTerminal("ImplicitlyUnwrappedOptionalType")
    let ProtocolCompositionType = NonTerminal("ProtocolCompositionType")
    let MetatypeType = NonTerminal("MetatypeType")
    //TaggedBlock
    let TaggedBlock = NonTerminal("TaggedBlock")
    let TaggedContent = NonTerminal("TaggedContent")
    let SelfClosingTag = NonTerminal("SelfClosingTag")
    let OpeningTag = NonTerminal("OpeningTag")
    let InsideTagContent = NonTerminal("InsideTagContent")
    let NestedTaggedBlock = NonTerminal("NestedTaggedBlock")
    let NestedOpeningTag = NonTerminal("NestedOpeningTag")
    let NestedSelfClosingTag = NonTerminal("NestedSelfClosingTag")
    let FreeOpeningTag = NonTerminal("FreeOpeningTag")
    let FreeSelfClosingTag = NonTerminal("FreeSelfClosingTag")
    //SimpleExpression
    let SimpleExpression = NonTerminal("SimpleExpression")
    let SimpleExpressionTail = NonTerminal("SimpleExpressionTail")
    //InlineBlock
    let InlineBlock = NonTerminal("InlineBlock")
    let InlineContent = NonTerminal("InlineContent")
    //LineBlock
    let LineBlock = NonTerminal("LineBlock")
    //Condition
    let ConditionList = NonTerminal("ConditionList")
    let Condition = NonTerminal("Condition")
    //
    let TypeCastingOperator = NonTerminal("TypeCastingOperator")
    let ConditionalOperator = NonTerminal("ConditionalOperator")
    //
    let Literal = NonTerminal("Literal")
    let ArrayLiteral = NonTerminal("ArrayLiteral")
    let DictionaryLiteral = NonTerminal("DictionaryLiteral")
    let ArrayLiteralItems = NonTerminal("ArrayLiteralItems")
    let ArrayLiteralItem = NonTerminal("ArrayLiteralItem")
    let DictionaryLiteralItems = NonTerminal("DictionaryLiteralItems")
    let DictionaryLiteralItem = NonTerminal("DictionaryLiteralItem")
    let NumericLiteral = NonTerminal("NumericLiteral")
    let BooleanLiteral = NonTerminal("BoolenLiteral")
    let NilLiteral = NonTerminal("NilLiteral")
    
    //
    let ParameterClause = NonTerminal("ParameterClause")
    let FunctionResult = NonTerminal("FunctionResult")
    let IdentifierList = NonTerminal("IdentifierList")
    let CaptureList = NonTerminal("CaptureList")
    let CaptureListItems = NonTerminal("CaptureListItems")
    let CaptureListItem = NonTerminal("CaptureListItem")
    let CaptureSpecifier = NonTerminal("CaptureSpecifier")

    //
    let ParameterList = NonTerminal("ParameterList")
    let Parameter = NonTerminal("Parameter")

    //
    let wl = NonTerminal("wl") {_ in BlockNode()}
    let Fail = FailPattern<ParsingState>()
    
    //MARK: Terminal symbols
    let PrefixOperator = Terminal(type: OperatorToken.self, "&", "+", "-", "!", "~", "++", "--")
    let PostfixOperator = Terminal(type: OperatorToken.self, "++", "--")
    let BinaryOperator = Terminal(type: OperatorToken.self, "+", "-", "*", "/", "%", "&+", "&-", "&*",
    "|","&","^","||","&&","??",
        "<<",">>",
    "==","!=","===","!==",">","<","<=","=>","~=")
    let AssignmentOperator = Terminal(type: OperatorToken.self, "=", "+=", "-=", "*=", "/=", "%=",
        "&+=", "&-=", "&*=", "<<=", ">>=",
        "|=","&=","^=","||=","&&=","??=")
    let TryOperator = "try" as Symbol<ParsingState>
    let Init = Terminal(IdentifierToken.self)
    let Identifier = Terminal(IdentifierToken.self)
    let IntegerLiteral = Terminal(IntegerToken.self)
    let FloatingPointLiteral = Terminal(FloatingPointToken.self)
    let StringLiteral = Terminal(StringToken.self)
    let HTMLText = Terminal(HTMLTextToken.self)
    let Dot = Terminal(DotToken.self)
    let DecimalDigits = Terminal(type: IntegerToken.self, {
        $0.rangeOfCharacter(from: CharacterSet(charactersIn: "xob_")) == nil
    })
    let ls = Terminal(NewLine.self) //line separator
    let ws = Terminal(WhiteSpace.self) //word separator
    let End = Terminal(EndToken.self)
    let SemiColon = ";" as Symbol<ParsingState>
    let TagStart = TagStartClass(TagOpener.self) //###TagStart needs its own class
    let FreeTagStart = Terminal(TagOpener.self)
    let NestedTagStart = TagStartClass(TagOpener.self) //TODO: implement ###TagStart needs its own class
    let MatchingClosingTag = TagEndClass(ClosingTag.self) //###TagEnd needs its own class
    let FreeClosingTag = Terminal(ClosingTag.self)
//    let TagEnd = TagEndClass(ClosingTag) //###TagEnd needs its own class
    let InlineStart = Terminal(InlineLeader.self)
    let LineStart = Terminal(LineEscape.self)
    
    //MARK: context control
    let psExpression = PushAndSetState<ParsingState>(.Expression)
    let psBlock = PushAndSetState<ParsingState>(.Block)
    let psTagEscape = PushAndSetState<ParsingState>(.TagEscape)
    let psLineEscape = PushAndSetState<ParsingState>(.LineEscape)
    let psSimple = PushAndSetState<ParsingState>(.Simple)
    let psInline = PushAndSetState<ParsingState>(.Inline)
    let psInTag = PushAndSetState<ParsingState>(.InsideTag)
    let pop = PopState<ParsingState>()
    
    //MARK: supplementary
    let ForHead = NonTerminal("ForHead")
    let CStyleForHeading =  NonTerminal("CStyleForHeading")
    
    override func setup() {
        wl ==> ws | ls
        
        Template ==> Statement+ & wl* & End
        //Statement
        //Statement.shouldReportMatches = true
        //Statement.shouldReportTests = true
        Statement ==> Expression & SemiColon.opt
        Statement |=> Declaration & SemiColon.opt
        Statement |=> LoopStatement & SemiColon.opt
        Statement |=> BranchStatement & SemiColon.opt
        Statement |=> LabeledStatement & SemiColon.opt
        Statement |=> ControlTransferStatement & SemiColon.opt
        Statement |=> DeferStatement & SemiColon.opt
        Statement |=> DoStatement & SemiColon.opt
        Statement |=> CompilerControlStatement
        Statement |=> HTMLOutputStatement
        Statement |=> TaggedBlock
        //
        LoopStatement ==> ForStatement | ForInStatement
        BranchStatement ==> IfStatement | GuardStatement | SwitchStatement
        DeferStatement ==> Fail
        DoStatement ==> Fail
        CompilerControlStatement ==> Fail
  
        //Expression.shouldReportTests = true
        Expression ==> TryOperator.opt & PrefixExpression & BinaryExpression*
        ExpressionList ==> Expression & (ws* & "," & wl* & Expression)*
        PrefixExpression ==> PrefixOperator* & PostfixExpression
        PrefixExpression |=> InOutExpression
        InOutExpression ==> "&" & Identifier
        PostfixExpression ==> PrimaryExpression & PostfixTail*
        PostfixTail ==> PostfixOperator
        PostfixTail |=> FunctionCallTail
        PostfixTail |=> InitializerTail
        PostfixTail |=> ExplicitMemberTail
        PostfixTail |=> PostfixSelfTail
        PostfixTail |=> DynamicTypeTail
        PostfixTail |=> SubscriptTail
        PostfixTail |=> ForcedValueTail
        PostfixTail |=> OptionalChainingTail
        FunctionCallTail ==> ParenthesizedExpression
        FunctionCallTail |=> ParenthesizedExpression.opt & TrailingClosure
        InitializerTail ==> wl* & Dot & "init"
        //ExplicitMemberTail.shouldReportTests = true
        ExplicitMemberTail ==> wl* & Dot & wl* & DecimalDigits
        ExplicitMemberTail |=> wl* & Dot & wl* & Identifier & wl* & GenericArgumentClause.opt
        PostfixSelfTail ==> wl* & Dot & "self"
        DynamicTypeTail ==> wl* & Dot & "dynamicType"
        TrailingClosure ==> ClosureExpression
        HTMLOutputStatement ==> wl* & HTMLText
        PrimaryExpression ==> Identifier & GenericArgumentClause.opt
        PrimaryExpression |=> LiteralExpression
        PrimaryExpression |=> SelfExpression
        PrimaryExpression |=> SuperclassExpression
        PrimaryExpression |=> ClosureExpression
        PrimaryExpression |=> ParenthesizedExpression
        PrimaryExpression |=> ImplicitMemberExpression
        PrimaryExpression |=> WildcardExpression
        //
        LiteralExpression ==> Literal
        LiteralExpression |=> ArrayLiteral | DictionaryLiteral
        LiteralExpression |=> AnySymbol("__FILE__","__LINE__","__COLUMN__","__FUNCTION__")
        ArrayLiteral ==> "[" & ArrayLiteralItems & "]"
        ArrayLiteralItems ==> ArrayLiteralItem & ("," & ArrayLiteralItem)* & ("," as Symbol).opt
        ArrayLiteralItem ==> Expression
        DictionaryLiteral ==> "[" & DictionaryLiteralItems & "]" | "[" & "|" & "]"
        DictionaryLiteralItems ==> DictionaryLiteralItem & ("," & DictionaryLiteralItem) & ("," as Symbol).opt
        DictionaryLiteralItem ==> Expression & ":" & Expression
        //
        Literal ==> NumericLiteral | StringLiteral | BooleanLiteral | NilLiteral
        NumericLiteral ==> ("-" as Symbol).opt & IntegerLiteral | ("-" as Symbol).opt & FloatingPointLiteral
        BooleanLiteral ==> AnySymbol("true", "false")
        NilLiteral ==> "nil" as Symbol
        //
        SelfExpression ==> "self" as Symbol
        SelfExpression |=> "self" & Dot & Identifier
        SelfExpression |=> "self" & "[" & ExpressionList & "]"
        SelfExpression |=> "self" & Dot & "init"
        //
        SuperclassExpression ==> "super" & Dot & Identifier
        SuperclassExpression |=> "super" & "[" & ExpressionList & "]"
        SuperclassExpression |=> "super" & Dot & "init"
        //
        ClosureExpression ==> "{" & ClosureSignature.opt & Statement* & "}"
        //
        ParenthesizedExpression ==> "(" & ExpressionElement* & ")"
        //
        ImplicitMemberExpression ==> "." & Identifier
        WildcardExpression ==> "_" as Symbol
        //
        ForHead ==> "for" & psExpression & wl*
        CStyleForHeading ==> (ForInit & wl*).opt & ";" & wl* & (Expression & wl*).opt & ";" & wl* & (Expression & wl*).opt
        ForStatement ==> ForHead & CStyleForHeading & CodeBlock & pop
        ForStatement |=> ForHead & "(" & wl* & CStyleForHeading & ")" & wl* & CodeBlock & pop
        ForInit ==> VariableDeclaration | ExpressionList
        //
        //ForInStatement.shouldReportTests = true
//        ForInStatement ==> ("for" as Symbol) & psExpression & wl* & ("case" as Symbol).opt & Pattern & wl* & ("in" as Symbol) & wl* & Expression & wl* & (WhereClause & wl*).opt & CodeBlock & pop
        ForInStatement ==> SequencePattern("for" as Symbol, psExpression, wl*, ("case" as Symbol).opt, Pattern, wl*, "in" as Symbol, wl*, Expression, wl*, (WhereClause & wl*).opt, CodeBlock, pop)

        //VariableDeclaration
        VariableDeclaration ==> VariableDeclarationHead & PatternInitializerList
        VariableDeclaration |=> VariableDeclarationHead & VariableName & TypeAnnotation & CodeBlock
        VariableDeclaration |=> VariableDeclarationHead & VariableName & TypeAnnotation & GetterSetterBlock
        VariableDeclaration |=> VariableDeclarationHead & VariableName & TypeAnnotation & GetterSetterKeywordBlock
        VariableDeclaration |=> VariableDeclarationHead & VariableName & Initializer & WillSetDidSetBlock
        VariableDeclaration |=> VariableDeclarationHead & VariableName & TypeAnnotation & Initializer.opt & WillSetDidSetBlock
        VariableDeclarationHead ==> Attribute* & DeclarationModifier* & "var"
        //
        Attribute ==> "@" & AttributeName & AttributeArgumentClause
//        DeclarationModifier ==> AnySymbol("class­","convenience­","dynamic","final­","infix­","lazy­","mutating­","nonmutating­","optional","override­","postfix","prefix­","required­","static­","unowned","weak")
//        | "unowned" & "­(" & "­safe" & ("­)" as Symbol)
//        | "unowned" & "­(" & "­unsafe" & ("­)" as Symbol)
        DeclarationModifier ==> AnySymbol("class­","convenience­","dynamic","final­","infix­","lazy­","mutating­","nonmutating­","optional","override­","postfix","prefix­","required­","static­","unowned","weak")
        DeclarationModifier |=> "unowned" & "­(" & "­safe" & ("­)" as Symbol)
        DeclarationModifier |=> "unowned" & "­(" & "­unsafe" & ("­)" as Symbol)
        DeclarationModifier |=> AccessLevelModifier
        AccessLevelModifier ==> ("internal­" as Symbol) | ("internal­" as Symbol) & "(" & "set" & ")"
        AccessLevelModifier |=> ("private" as Symbol) | ("private" as Symbol) & "(" & "set" & ")"
        AccessLevelModifier |=> ("public­" as Symbol) | ("public­" as Symbol) & "(" & "set" & ")"
        //
        IfStatement ==> "if" & psExpression & wl* & ConditionClause & wl* & CodeBlock & wl* & ElseClause.opt & pop
        ElseClause ==> "else" & wl* & CodeBlock | "else" & wl* & IfStatement
        
        Pattern ==> SubPattern & ("as" & TypeRef).opt
        //SubPattern.shouldReportTests = true
        SubPattern ==> IdentifierPattern & TypeAnnotation.opt
        SubPattern |=> ValueBindingPattern
        SubPattern |=> TuplePattern & TypeAnnotation.opt
        SubPattern |=> EnumCasePattern
        SubPattern |=> OptionalPattern
        SubPattern |=> TypeCastingPattern
        SubPattern |=> ExpressionPattern
        //
        IdentifierPattern ==> Identifier
        ValueBindingPattern ==> "var" & Pattern | "let" & Pattern
        TuplePattern ==> "(" & TuplePatternElementList & ")"
        TuplePatternElementList ==> TuplePatternElement & ("," & TuplePatternElement)*
        TuplePatternElement ==> Pattern
        EnumCasePattern ==> TypeIdentifier.opt & EnumCaseName & TuplePattern.opt
        EnumCaseName ==> Identifier
        TypeIdentifier ==> TypeName & GenericArgumentClause.opt & ("." & TypeIdentifier)*
        TypeName ==> Identifier
        OptionalPattern ==> IdentifierPattern & "?"
        TypeCastingPattern ==> IsPattern
        IsPattern ==> "is" & TypeRef
        ExpressionPattern ==> Expression
        //
        Declaration ==> ImportDeclaration
        Declaration |=> ConstantDeclaration
        Declaration |=> VariableDeclaration
        Declaration |=> TypealiasDeclaration
        Declaration |=> FunctionDeclaration
        Declaration |=> EnumDeclaration
        Declaration |=> StructDeclaration
        Declaration |=> ClassDeclaration
        Declaration |=> ProtocolDeclaration
        Declaration |=> InitializerDeclaration
        Declaration |=> DeinitializerDeclaration
        Declaration |=> ExtensionDeclaration
        Declaration |=> SubscriptDeclaration
        Declaration |=> OperaotrDeclaration
        //
        ImportDeclaration ==> Fail
        ConstantDeclaration ==> Fail
        TypealiasDeclaration ==> Fail
        FunctionDeclaration ==> Fail
        EnumDeclaration ==> Fail
        StructDeclaration ==> Fail
        ClassDeclaration ==> Fail
        ProtocolDeclaration ==> Fail
        InitializerDeclaration ==> Fail
        DeinitializerDeclaration ==> Fail
        ExtensionDeclaration ==> Fail
        SubscriptDeclaration ==> Fail
        OperaotrDeclaration ==> Fail
        
        //BranchStatement
        GuardStatement ==> Fail
        SwitchStatement ==> Fail
        
        //LabeledStatement
        LabeledStatement ==> Fail
        
        //ControlTransferStatement
        ControlTransferStatement ==> BreakStatement
        ControlTransferStatement |=> ContinueStatement
        ControlTransferStatement |=> FallthroughStatement
        ControlTransferStatement |=> ReturnStatement
        ControlTransferStatement |=> ThrowStatement
        //
        BreakStatement ==> Fail
        ContinueStatement ==> Fail
        FallthroughStatement ==> Fail
        ReturnStatement ==> Fail
        ThrowStatement ==> Fail
        
        //TypeAnnotation
        TypeAnnotation ==> Attribute* & TypeRef
        TypeRef ==> ArrayType
        TypeRef |=> DictionaryType
        TypeRef |=> FunctionType
        TypeRef |=> TypeIdentifier
        TypeRef |=> TupleType
        TypeRef |=> OptionalType
        TypeRef |=> ImplicitlyUnwrappedOptionalType
        TypeRef |=> ProtocolCompositionType
        TypeRef |=> MetatypeType
        //
        ArrayType ==> Fail
        DictionaryType ==> Fail
        FunctionType ==> Fail
        TupleType ==> Fail
        OptionalType ==> Fail
        ImplicitlyUnwrappedOptionalType ==> Fail
        ProtocolCompositionType ==> Fail
        MetatypeType ==> Fail
        //
        GenericArgumentClause ==> Fail
        SubscriptTail ==> Fail
        ForcedValueTail ==> Fail
        OptionalChainingTail ==> Fail
        //
        BinaryExpression ==> BinaryOperator & PrefixExpression
        BinaryExpression |=> wl+ & BinaryOperator & wl+ & PrefixExpression
        BinaryExpression |=> AssignmentOperator & TryOperator.opt & wl* & PrefixExpression
        BinaryExpression |=> wl+ & AssignmentOperator & wl+ & (TryOperator & wl*).opt & PrefixExpression
        BinaryExpression |=> wl+ & ConditionalOperator & wl+ & (TryOperator & wl*).opt & PrefixExpression
        BinaryExpression |=> wl* & TypeCastingOperator
        //
        TypeCastingOperator ==> "is" & wl* & TypeRef
        TypeCastingOperator |=> "as" & wl* & TypeRef
        TypeCastingOperator |=> "as" & "?" & wl* & TypeRef
        TypeCastingOperator |=> "as" & "!" & wl* & TypeRef
        //
        ConditionalOperator ==> "?" & (wl+ & TryOperator).opt & wl+ & ":"
        //
        WhereClause ==> Fail
    
        //CodeBlock
        //CodeBlock.shouldReportTests = true
        CodeBlock ==> "{" & psBlock & (wl* & Statement)* & wl* & "}" & pop
        CodeBlock |=> InlineBlock
        
        //TaggedBlock
        //TaggedBlock.shouldReportTests = true
        //###Needs refinement
        TaggedBlock ==> OpeningTag & TaggedContent* & MatchingClosingTag
        TaggedBlock |=> SelfClosingTag
        //TaggedContent.shouldReportTests = true
        TaggedContent ==> InsideTagContent | NestedTaggedBlock
        TaggedContent |=> FreeOpeningTag | FreeSelfClosingTag | FreeClosingTag
        //NestedTaggedBlock
        NestedTaggedBlock ==> NestedOpeningTag & TaggedContent* & MatchingClosingTag
        NestedTaggedBlock |=> NestedSelfClosingTag
        //OpeningTag
        OpeningTag ==> TagStart & psInTag & InsideTagContent* & ">" & pop
        //NestedOpeningTag
        NestedOpeningTag ==> NestedTagStart & psInTag & InsideTagContent* & ">" & pop
        //FreeOpeningTag
        FreeOpeningTag ==> FreeTagStart & psInTag & InsideTagContent* & ">" & pop
        //SelfClosingTag
        SelfClosingTag ==> TagStart & psInTag & InsideTagContent* & "/>" & pop & pop
        //NestedSelfClosingTag
        NestedSelfClosingTag ==> NestedTagStart & psInTag & InsideTagContent* & "/>" & pop & pop
        //FreeSelfClosingTag
        FreeSelfClosingTag ==> FreeTagStart & psInTag & InsideTagContent* & "/>" & pop
        //InsideTagContent
        InsideTagContent ==> HTMLText
        InsideTagContent |=> IfStatement | ForStatement | ForInStatement
        InsideTagContent |=> SimpleExpression
        //
        //SimpleExpression.shouldReportMatches = true
        SimpleExpression |=> Identifier & psSimple & SimpleExpressionTail*-> & pop
        //SimpleExpressionTail.shouldReportMatches = true
        SimpleExpressionTail ==> "." & Identifier
        SimpleExpressionTail |=> "." & DecimalDigits
        SimpleExpressionTail |=> "." & "self"
        SimpleExpressionTail |=> "[" & wl* & ExpressionList & wl* & "]"
        SimpleExpressionTail |=> ParenthesizedExpression
        SimpleExpressionTail |=> TrailingClosure
        SimpleExpressionTail |=> PostfixOperator
        
        //InlineBlock
        //InlineBlock.shouldReportTests = true
        //###Needs refinement
        InlineBlock ==> InlineStart & psInline & InlineContent* & "}" & pop
        //InlineContent.shouldReportTests = true
        InlineContent ==> HTMLText
        InlineContent |=> IfStatement | ForStatement | ForInStatement
        InlineContent |=> SimpleExpression
        
        //LineBlock
        //LineBlock.shouldReportTests = true
        //###Needs refinement
        LineBlock ==> LineStart & psLineEscape & InlineContent* & ls & pop
        
        //ConditionClause
        //ConditionClause.shouldReportTests = true
        ConditionClause ==> ConditionList
        ConditionClause |=> Expression & ("," & ConditionList).opt
        ConditionList ==> Condition & ("," & Condition)*
        Condition ==> Fail

        //ClosureSignature
        ClosureSignature ==> ParameterClause & FunctionResult.opt & "in"
        ClosureSignature |=> IdentifierList & FunctionResult.opt & "in"
        ClosureSignature |=> CaptureList & ParameterClause & FunctionResult.opt & "in"
        ClosureSignature |=> CaptureList & IdentifierList & FunctionResult.opt & "in"
        ClosureSignature |=> CaptureList & FunctionResult.opt & "in"
        CaptureList ==> "[" & CaptureListItems & "]"
        CaptureListItems ==> CaptureListItem & ("," & CaptureListItem)*
        CaptureListItem ==> CaptureSpecifier & Expression
//        CaptureSpecifier ==> AnySymbol("weak", "unowned") | ("unonwed" as Symbol) & "(" & "safe" & ")" |  ("unonwed" as Symbol) & "(" & "unsafe" & ")"
        CaptureSpecifier ==> AnySymbol("weak", "unowned")
        CaptureSpecifier |=> ("unonwed" as Symbol) & "(" & "safe" & ")"
        CaptureSpecifier |=> ("unonwed" as Symbol) & "(" & "unsafe" & ")"

        
        //ParameterClause
        ParameterClause ==> "(" & ")" | "(" & ParameterList & ")"
        ParameterList ==> Parameter & ("," & Parameter)*
        
        //IdentifierList
        IdentifierList ==> Identifier & ("," & Identifier)*
        
    }
    
    var _state: ParsingState = ParsingState()
    override var state: ParsingState {
        get {
            _state.currentPosition = tokenizer.currentPosition
            return _state
        }
        set {
            _state = newValue
            tokenizer.currentPosition = _state.currentPosition
        }
    }
    
    override init(tokenizer: TokenizerBase<LexicalContext>) {
        super.init(tokenizer: tokenizer)
    }
}
