//
//  SyntaxFactory+Extensions.swift
//  speck
//
//  Created by Eric Rabil on 11/17/21.
//

import Foundation
import SwiftSyntax

/*
 SyntaxFactory.makeFunctionDecl(
     attributes: nil,
     modifiers: SyntaxFactory.makeModifierList([
         SyntaxFactory.makeDeclModifier(
             name: SyntaxFactory.makePublicKeyword(),
             detailLeftParen: nil,
             detail: nil,
             detailRightParen: nil
         ).withTrailingTrivia(.spaces(1))
     ]),
     funcKeyword: SyntaxFactory.makeFuncKeyword(),
     identifier: SyntaxFactory.makeIdentifier("encode").withLeadingTrivia(.spaces(1)),
     genericParameterClause: nil,
     signature: SyntaxFactory.makeFunctionSignature(
         input: SyntaxFactory.makeParameterClause(
             leftParen: SyntaxFactory.makeLeftParenToken(),
             parameterList: SyntaxFactory.makeFunctionParameterList([
                 SyntaxFactory.makeFunctionParameter(
                     attributes: nil,
                     firstName: SyntaxFactory.makeIdentifier("to").withTrailingTrivia(.spaces(1)),
                     secondName: SyntaxFactory.makeIdentifier("encoder"),
                     colon: SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)),
                     type: SyntaxFactory.makeTypeIdentifier("Encoder"),
                     ellipsis: nil,
                     defaultArgument: nil,
                     trailingComma: nil
                 )
             ]),
             rightParen: SyntaxFactory.makeRightParenToken().withTrailingTrivia(.spaces(1))
         ),
         asyncOrReasyncKeyword: nil,
         throwsOrRethrowsKeyword: SyntaxFactory.makeThrowsKeyword().withTrailingTrivia(.spaces(1)),
         output: nil
     ),
     genericWhereClause: nil,
     body: SyntaxFactory.makeCodeBlock(
         leftBrace: SyntaxFactory.makeLeftBraceToken().withTrailingTrivia(.newlines(1)),
         statements: SyntaxFactory.makeCodeBlockItemList([
             
         ]),
         rightBrace: SyntaxFactory.makeRightBraceToken()
     )
 )
 */

enum SwiftAccessibility {
    case `public`, `private`, `internal`, `fileprivate`
    
    var keyword: TokenSyntax {
        switch self {
        case .public: return SyntaxFactory.makePublicKeyword()
        case .private: return SyntaxFactory.makePrivateKeyword()
        case .internal: return SyntaxFactory.makeInternalKeyword()
        case .fileprivate: return SyntaxFactory.makeFileprivateKeyword()
        }
    }
    
    var decl: DeclModifierSyntax {
        SyntaxFactory.makeDeclModifier(
            name: keyword,
            detailLeftParen: nil,
            detail: nil,
            detailRightParen: nil
        )
    }
}

extension SyntaxFactory {
    static func makeExtension(ofType type: String, inheritances: [String]?, declarations: [DeclSyntaxProtocol]) -> DeclSyntax {
        DeclSyntax(
            SyntaxFactory.makeExtensionDecl(
                attributes: nil,
                modifiers: nil,
                extensionKeyword: SyntaxFactory.makeExtensionKeyword().withTrailingTrivia(.spaces(1)),
                extendedType: SyntaxFactory.makeTypeIdentifier(type),
                inheritanceClause: inheritances.map(SyntaxFactory.makeInheritanceList(fromLiterals:)),
                genericWhereClause: nil,
                members: SyntaxFactory.makeMemberDeclBlock(
                    leftBrace: SyntaxFactory.makeLeftBraceToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.newlines(1)),
                    members: SyntaxFactory.makeMemberDeclList(declarations.map {
                        SyntaxFactory.makeMemberDeclListItem(decl: DeclSyntax(Syntax(fromProtocol: $0))!, semicolon: nil)
                    }),
                    rightBrace: SyntaxFactory.makeRightBraceToken().withLeadingTrivia(.newlines(1))
                )
            )
        )
    }
    
    static func makeFunction(withName name: String, specialized: Bool = false, accessibility: SwiftAccessibility, signature: FunctionSignatureSyntax, body: CodeBlockSyntax?) -> FunctionDeclSyntax {
        SyntaxFactory.makeFunctionDecl(
            attributes: nil,
            modifiers: SyntaxFactory.makeModifierList([
                accessibility.decl.withTrailingTrivia(.spaces(specialized ? 0 : 1))
            ]),
            funcKeyword: specialized ? SyntaxFactory.makeUnknown("") : SyntaxFactory.makeFuncKeyword(),
            identifier: SyntaxFactory.makeIdentifier(name).withLeadingTrivia(.spaces(1)),
            genericParameterClause: nil,
            signature: signature,
            genericWhereClause: nil,
            body: body
        )
    }
    
    
}
