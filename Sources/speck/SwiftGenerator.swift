//
//  SwiftGenerator.swift
//  speck
//
//  Created by Eric Rabil on 11/16/21.
//

import Foundation
import SwiftSyntax
import _InternalSwiftSyntaxParser
import CoreSpeck

class SwiftGenerator: SpecMasher {
}

extension TypeSyntax {
    var optional: TypeSyntax {
        TypeSyntax(SyntaxFactory.makeOptionalType(wrappedType: self, questionMark: SyntaxFactory.makePostfixQuestionMarkToken()))
    }
}

private let PROTOCOL_GET_SET = Syntax(SyntaxFactory.makeAccessorList([
    SyntaxFactory.makeAccessorDecl (
        attributes: nil,
        modifier: nil,
        accessorKind: SyntaxFactory.makeStringLiteral("{ get"),
        parameter: nil,
        asyncKeyword: nil,
        throwsKeyword: nil,
        body: nil
    ).withTrailingTrivia(.spaces(1)),
    SyntaxFactory.makeAccessorDecl (
        attributes: nil,
        modifier: nil,
        accessorKind: SyntaxFactory.makeStringLiteral("set }"),
        parameter: nil,
        asyncKeyword: nil,
        throwsKeyword: nil,
        body: nil
    )
]).withLeadingTrivia(.spaces(1)))

extension SpecType {
    var unwrappedSwiftType: TypeSyntax {
        switch self {
        case let spec as SpecPrimitive:
            switch spec.primitiveKind {
            case .data: return SyntaxFactory.makeTypeIdentifier("Data")
            case .date: return SyntaxFactory.makeTypeIdentifier("Date")
            case .bool: return SyntaxFactory.makeTypeIdentifier("Bool")
            case .integer: return SyntaxFactory.makeTypeIdentifier("Int")
            case .double: return SyntaxFactory.makeTypeIdentifier("Double")
            case .string: return SyntaxFactory.makeTypeIdentifier("String")
            case .never: return SyntaxFactory.makeTypeIdentifier("()")
            }
        case let spec as SpecAlias:
            return SyntaxFactory.makeTypeIdentifier(spec.aliasedName)
        case let spec as SpecCluster:
            switch spec {
            case .array(let element, _):
                return TypeSyntax(
                    SyntaxFactory.makeArrayType (
                        leftSquareBracket: SyntaxFactory.makeLeftSquareBracketToken(),
                        elementType: element.swiftType,
                        rightSquareBracket: SyntaxFactory.makeRightSquareBracketToken()
                    )
                )
            case .dictionary(let key, let element, _):
                return TypeSyntax(
                    SyntaxFactory.makeDictionaryType (
                        leftSquareBracket: SyntaxFactory.makeLeftSquareBracketToken(),
                        keyType: key.swiftType,
                        colon: SyntaxFactory.makeColonToken(),
                        valueType: element.swiftType,
                        rightSquareBracket: SyntaxFactory.makeRightSquareBracketToken()
                    )
                )
            }
        default:
            return TypeSyntax(SyntaxFactory.makeBlankSomeType())
        }
    }
    
    var swiftType: TypeSyntax {
        if metadata.annotations[AnnotationKey.nullable] == "true" {
            return unwrappedSwiftType.optional
        }
        
        return unwrappedSwiftType
    }
}

extension SpecPrimitive.Kind {
    var literalExpressionType: String? {
        switch self {
        case .string: return "ExpressibleByStringLiteral"
        case .integer: return "ExpressibleByIntegerLiteral"
        case .double: return "ExpressibleByFloatLiteral"
        case .bool: return "ExpressibleByBooleanLiteral"
        case .never: return nil
        case .date: return nil
        case .data: return nil
        }
    }
    
    var literalInitLabel: String? {
        switch self {
        case .string: return "stringLiteral"
        case .integer: return "integerLiteral"
        case .double: return "floatLiteral"
        case .bool: return "booleanLiteral"
        case .never: return nil
        case .date: return nil
        case .data: return nil
        }
    }
}

extension SwiftGenerator {
    private func _renderClosedEnum(type: SpecEnumeration) -> DeclSyntax {
        DeclSyntax(
            SyntaxFactory.makeEnumDecl(
                attributes: nil,
                modifiers: nil,
                enumKeyword: SyntaxFactory.makeEnumKeyword(leadingTrivia: .zero, trailingTrivia: .spaces(1)),
                identifier: SyntaxFactory.makeIdentifier(type.name),
                genericParameters: nil,
                inheritanceClause: SyntaxFactory.makeInheritanceList(fromTypes: [
                    SpecPrimitive(kind: type.enumerationKind).swiftType,
                    SyntaxFactory.makeTypeIdentifier("Codable"),
                    SyntaxFactory.makeTypeIdentifier("Equatable"),
                    SyntaxFactory.makeTypeIdentifier("Hashable")
                ]).withTrailingTrivia(.spaces(1)),
                genericWhereClause: nil,
                members: SyntaxFactory.makeMemberDeclBlock(
                    leftBrace: SyntaxFactory.makeLeftBraceToken(leadingTrivia: .zero, trailingTrivia: .spaces(1).appending(.newlines(1))),
                    members: SyntaxFactory.makeMemberDeclList(
                        type.cases.map { name, value in
                            SyntaxFactory.makeMemberDeclListItem(
                                decl: DeclSyntax(
                                    SyntaxFactory.makeEnumCaseDeclaration (
                                        withName: name,
                                        typeBinding: nil,
                                        equalTo: (
                                            type.enumerationKind == .string ? (
                                                ExprSyntax(SyntaxFactory.makeStringLiteralExpr(value))
                                            ) : (
                                                ExprSyntax(SyntaxFactory.makeIntegerLiteralExpr(digits: SyntaxFactory.makeUnknown(value)))
                                            )
                                        )
                                    )
                                ),
                                semicolon: nil
                            ).withTrailingTrivia(.newlines(1)).withLeadingTrivia(.tabs(1))
                        }
                    ),
                    rightBrace: SyntaxFactory.makeRightBraceToken()
                )
            )
        )
    }
    
    func renderEnum(type: SpecEnumeration) -> DeclSyntax? {
//        if type.extensible {
//            guard let literalExpressionType = type.enumerationKind.literalExpressionType, literalExpressionLabel = type.enumerationKind.literalInitLabel else {
//                return nil
//            }
//            fatalError()
            
//            return DeclSyntax(
//                SyntaxFactory.makeStructDecl(
//                    attributes: nil,
//                    modifiers: nil,
//                    structKeyword: SyntaxFactory.makeStructKeyword(leadingTrivia: .zero, trailingTrivia: .spaces(1)),
//                    identifier: SyntaxFactory.makeIdentifier(type.name),
//                    genericParameterClause: nil,
//                    inheritanceClause: SyntaxFactory.makeInheritanceList(fromTypes: [
//                        SyntaxFactory.makeTypeIdentifier(literalExpressionType),
//                        SyntaxFactory.makeTypeIdentifier("RawRepresentable"),
//                        SyntaxFactory.makeTypeIdentifier("Codable")
//                    ]),
//                    genericWhereClause: nil,
//                    members: SyntaxFactory.makeMemberDeclBlock(
//                        leftBrace: SyntaxFactory.makeLeftBraceToken(leadingTrivia: .zero, trailingTrivia: .spaces(1).appending(.newlines(1))),
//                        members: SyntaxFactory.makeMemberDeclList([
//
//                        ]),
//                        rightBrace: SyntaxFactory.makeRightBraceToken()
//                    )
//                )
//            )
//        } else {
            return _renderClosedEnum(type: type)
//        }
    }
    
    func renderNode(node: SpecNode) -> DeclSyntax {
        let typeGroupDefs = (SpecificationRegistry.shared.query(kind: .typeGroup, name: node.name) as? TypeGroup) ?? TypeGroup(name: node.name)
        
        var identifier = SyntaxFactory.makeIdentifier(node.name, leadingTrivia: .zero, trailingTrivia: .zero)
        var inheritance = SyntaxFactory.makeInheritanceList(
            fromLiterals: (
                typeGroupDefs.settings.generationStyle == .concrete ? ["Hashable", "Equatable"] : []
            ) + typeGroupDefs.settings.explicitlyExtends
         )?.withTrailingTrivia(.spaces(1))
        
        if inheritance == nil {
            identifier = identifier.withTrailingTrivia(.spaces(1))
        }
        
        func renderMemberListItem(forSpec spec: SpecType, name: String) -> DeclSyntax {
            var decl = SyntaxFactory.makeVariableDeclaration (
                withName: name,
                type: spec.swiftType,
                letOrVar: .var,
                accessor: typeGroupDefs.settings.generationStyle == .abstract ? PROTOCOL_GET_SET : nil
            ).withLeadingTrivia(.tabs(1))
            
            if let description = spec.metadata.description {
                decl = decl.withLeadingTrivia(.tabs(1) + .docLineComment("/// \(description)") + .newlines(1) + .tabs(1))
            }
            
            return DeclSyntax(decl)
        }
        
        let memberList = SyntaxFactory.makeMemberDeclBlock(
            leftBrace: SyntaxFactory.makeLeftBraceToken(leadingTrivia: .zero, trailingTrivia: .spaces(1).appending(.newlines(1))),
            members: SyntaxFactory.makeMemberDeclList(
                (inheritedProperties(forNodeName: node.name) + node.children).map { name, spec in
                    SyntaxFactory.makeMemberDeclListItem(
                        decl: renderMemberListItem(forSpec: spec, name: spec.metadata.annotations[AnnotationKey.readableName] ?? name),
                        semicolon: nil
                    ).withTrailingTrivia(.newlines(1))
                }
            ),
            rightBrace: SyntaxFactory.makeRightBraceToken()
        )
        
        if typeGroupDefs.settings.generationStyle == .abstract {
            return DeclSyntax(
                SyntaxFactory.makeProtocolDecl(
                    attributes: nil,
                    modifiers: nil,
                    protocolKeyword: SyntaxFactory.makeProtocolKeyword(leadingTrivia: Trivia.zero, trailingTrivia: Trivia.spaces(1)),
                    identifier: identifier,
                    inheritanceClause: inheritance,
                    genericWhereClause: nil,
                    members: memberList
                )
            )
        }
        
        return DeclSyntax(
            SyntaxFactory.makeStructDecl(
                attributes: nil,
                modifiers: nil,
                structKeyword: SyntaxFactory.makeStructKeyword(leadingTrivia: Trivia.zero, trailingTrivia: Trivia.spaces(1)),
                identifier: identifier,
                genericParameterClause: nil,
                inheritanceClause: inheritance,
                genericWhereClause: nil,
                members: memberList
            )
        )
    }
    
    func renderTypeGroups() -> [DeclSyntax] {
        nodes.values.map(renderNode(node:))
    }
    
    func renderOthers() -> [DeclSyntax] {
        var declarations: [DeclSyntax] = []
        
        for other in types.values {
            switch other {
            case is SpecNode:
                continue
            case let other as SpecEnumeration:
                if let rendered = renderEnum(type: other) {
                    declarations.append(rendered)
                }
            default:
                continue
            }
        }
        
        return declarations
    }
    
    func renderEverything() -> [DeclSyntax] {
        renderTypeGroups() + renderOthers() + renderEncodableConformances()
    }
}
