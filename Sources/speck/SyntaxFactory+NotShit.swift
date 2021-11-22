//
//  SyntaxFactory+NotShit.swift
//  speck
//
//  Created by Eric Rabil on 11/16/21.
//

import Foundation
import SwiftSyntax
import _InternalSwiftSyntaxParser

extension SyntaxFactory {
    static func makeInheritanceList(fromLiterals strings: [String]) -> TypeInheritanceClauseSyntax? {
        if strings.count == 0 {
            return nil
        }
        
        return makeInheritanceList(fromTypes: strings.map {
            SyntaxFactory.makeTypeIdentifier($0)
        })
    }
    
    static func makeInheritanceList(fromTypes types: [TypeSyntax]) -> TypeInheritanceClauseSyntax {
        SyntaxFactory.makeTypeInheritanceClause (
            colon: SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)),
            inheritedTypeCollection: SyntaxFactory.makeInheritedTypeList(types.enumerated().map { index, type in
                SyntaxFactory.makeInheritedType(
                    typeName: type,
                    trailingComma: index != types.count - 1 ? SyntaxFactory.makeCommaToken().withTrailingTrivia(.spaces(1)) : nil
                )
            })
        )
    }
    
    static func makeIdentifierPattern(fromString string: String) -> PatternSyntax {
        PatternSyntax (
            SyntaxFactory.makeIdentifierPattern (
                identifier: SyntaxFactory.makeIdentifier(string)
            )
        )
    }
    
    enum LetOrVar {
        case `let`, `var`
        
        func make() -> TokenSyntax {
            switch self {
            case .var:
                return SyntaxFactory.makeVarKeyword(leadingTrivia: .zero, trailingTrivia: .spaces(1))
            case .let:
                return SyntaxFactory.makeLetKeyword(leadingTrivia: .zero, trailingTrivia: .spaces(1))
            }
        }
    }
    
    static func makeEnumCaseDeclaration(withName name: String, typeBinding: ParameterClauseSyntax?, equalTo: ExprSyntax?) -> EnumCaseDeclSyntax {
        SyntaxFactory.makeEnumCaseDecl(
            attributes: nil,
            modifiers: nil,
            caseKeyword: SyntaxFactory.makeCaseKeyword().withTrailingTrivia(.spaces(1)),
            elements: SyntaxFactory.makeEnumCaseElementList([
                SyntaxFactory.makeEnumCaseElement(
                    identifier: SyntaxFactory.makeIdentifier(name),
                    associatedValue: typeBinding,
                    rawValue: equalTo.map { equalTo in
                        SyntaxFactory.makeInitializerClause(equal: SyntaxFactory.makeEqualToken(leadingTrivia: .spaces(1), trailingTrivia: .spaces(1)), value: equalTo)
                    },
                    trailingComma: nil
                )
            ])
        )
    }
    
    static func makeVariableDeclaration(withName name: String, type: TypeSyntax?, letOrVar: LetOrVar?, accessor: Syntax?, initializer: InitializerClauseSyntax? = nil) -> VariableDeclSyntax {
        SyntaxFactory.makeVariableDecl(
            attributes: nil,
            modifiers: nil,
            letOrVarKeyword: letOrVar?.make() ?? SyntaxFactory.makeUnknown(""),
            bindings: SyntaxFactory.makePatternBindingList([
                SyntaxFactory.makePatternBinding (
                    pattern: makeIdentifierPattern(fromString: name),
                    typeAnnotation: type.map { type in
                        SyntaxFactory.makeTypeAnnotation(colon: SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)), type: type)
                    },
                    initializer: initializer,
                    accessor: accessor,
                    trailingComma: nil
                )
            ])
        )
    }
}
