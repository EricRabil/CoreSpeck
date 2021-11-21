//
//  CodableGenerator.swift
//  speck
//
//  Created by Eric Rabil on 11/16/21.
//

import Foundation
import CoreSpeck
import SwiftSyntax

extension String: ExprSyntaxProtocol {
    public init?(_ syntaxNode: Syntax) {
        self = syntaxNode.description
    }
    
    public var _syntaxNode: Syntax {
        Syntax(SyntaxFactory.makeIdentifierExpr(identifier: SyntaxFactory.makeIdentifier(self), declNameArguments: nil))
    }
    
    public func _validateLayout() {
        
    }
    
    public var syntaxNodeType: SyntaxProtocol.Type {
        ExprSyntax.self
    }
}

struct FunctionParameter {
    private static func _identifier(_ text: String) -> ExprSyntax {
        ExprSyntax(SyntaxFactory.makeIdentifierExpr(identifier: SyntaxFactory.makeIdentifier(text), declNameArguments: nil))
    }
    
    static func lastParameter<Expr: ExprSyntaxProtocol>(withLabel label: String?, expression: Expr) -> FunctionParameter {
        FunctionParameter(label: label, isLast: true, expression: ExprSyntax(expression))
    }
    
    static func lastParameter<Expr: ExprSyntaxProtocol>(withExpression expression: Expr) -> FunctionParameter {
        lastParameter(withLabel: nil, expression: expression)
    }
    
    static func parameter<Expr: ExprSyntaxProtocol>(withLabel label: String?, expression: Expr) -> FunctionParameter {
        FunctionParameter(label: label, isLast: false, expression: ExprSyntax(expression))
    }
    
    static func parameter<Expr: ExprSyntaxProtocol>(withExpression expression: Expr) -> FunctionParameter {
        parameter(withLabel: nil, expression: expression)
    }
    
    var label: String?
    var isLast: Bool
    var expression: ExprSyntax
    
    var tupleElement: TupleExprElementSyntax {
        SyntaxFactory.makeTupleExprElement(
            label: label.map { SyntaxFactory.makeIdentifier($0) },
            colon: label.map { _ in SyntaxFactory.makeColonToken(leadingTrivia: .zero, trailingTrivia: .spaces(1)) },
            expression: expression,
            trailingComma: isLast ? nil : SyntaxFactory.makeCommaToken().withTrailingTrivia(.spaces(1))
        )
    }
}

private func generateFunctionCall(
    onVariable variableName: String, parameters: [FunctionParameter]
) -> FunctionCallExprSyntax {
    SyntaxFactory.makeFunctionCallExpr(
        calledExpression: ExprSyntax(
            SyntaxFactory.makeVariableExpr(variableName, leadingTrivia: .zero, trailingTrivia: .zero)
        ),
        leftParen: SyntaxFactory.makeLeftParenToken(),
        argumentList: SyntaxFactory.makeTupleExprElementList(parameters.map(\.tupleElement)),
        rightParen: SyntaxFactory.makeRightParenToken(),
        trailingClosure: nil,
        additionalTrailingClosures: nil
    )
}

private func generateVariableAssignment(
    letOrVar: SyntaxFactory.LetOrVar?,
    name: String,
    type: TypeSyntax?,
    assignment: ExprSyntax
) -> DeclSyntax {
    DeclSyntax(
        SyntaxFactory.makeVariableDeclaration(
            withName: name,
            type: type,
            letOrVar: letOrVar,
            accessor: nil,
            initializer: SyntaxFactory.makeInitializerClause(
                equal: SyntaxFactory.makeEqualToken(leadingTrivia: .spaces(1), trailingTrivia: .spaces(1)),
                value: assignment
            )
        )
    )
}

private func generateEncodingStatement(_ containerName: String, _ functionName: String, _ selfPropertyName: String, _ encodedName: String) -> FunctionCallExprSyntax {
    generateFunctionCall(
        onVariable: "try \(containerName).\(functionName)",
        parameters: [
            .parameter(withExpression: selfPropertyName),
            .lastParameter(withLabel: "forKey", expression: SyntaxFactory.makeStringLiteralExpr(encodedName))
        ]
    )
}

private func generateDecodingStatement(_ containerName: String, _ functionName: String, _ selfPropertyName: String, _ propertyType: String, _ encodedName: String) -> SyntaxProtocol {
    generateVariableAssignment(letOrVar: nil, name: selfPropertyName, type: nil, assignment: ExprSyntax(generateFunctionCall(
        onVariable: "try \(containerName).\(functionName)",
        parameters: [
            .parameter(withExpression: propertyType),
            .lastParameter(withLabel: "forKey", expression: SyntaxFactory.makeStringLiteralExpr(encodedName))
        ]
    )))
}

private extension SpecType {
    var isAggregate: Bool {
        metadata.annotations[AnnotationKey.synthesizedAggregate] != nil
    }
    
    var isOptional: Bool {
        metadata.annotations[AnnotationKey.nullable] == "true"
    }
    
    var encodingFunction: String {
        isOptional ? "encodeIfPresent" : "encode"
    }
    
    var decodingFunction: String {
        isOptional ? "decodeIfPresent" : "decode"
    }
}

extension SpecNode {
    func generatedName(forName name: String) -> String {
        children[name]?.metadata.annotations[AnnotationKey.readableName] ?? name
    }
    
    func encodingExpressions(accessorPrefix: String = "", typeGroups: [String: SpecNode]) -> [SyntaxProtocol] {
        children.flatMap { name, node -> [SyntaxProtocol] in
            if node.isAggregate {
                return [
                    generateFunctionCall(onVariable: "try " + (accessorPrefix.isEmpty ? "" : accessorPrefix.appending(".")) + name.appending(node.isOptional ? "?." : ".") + "encode", parameters: [
                        .lastParameter(withLabel: "to", expression: "encoder")
                    ])
                ]
            } else {
                return [generateEncodingStatement("container", accessorPrefix.contains("?.") ? "encodeIfPresent" : node.encodingFunction, accessorPrefix + generatedName(forName: name), name)]
            }
        }
    }
    
    func decodingExpressions(accessorPrefix: String = "", typeGroups: [String: SpecNode]) -> [SyntaxProtocol] {
        children.flatMap { name, node -> [SyntaxProtocol] in
            if let aggregateName = node.metadata.annotations[AnnotationKey.synthesizedAggregate] {
                return [
                    generateVariableAssignment(letOrVar: nil, name: name, type: nil, assignment: ExprSyntax((node.isOptional ? "try?" : "try") + " \(aggregateName)(from: decoder)"))
                ]
            } else {
                return [generateDecodingStatement("container", accessorPrefix.contains("?.") ? "decodeIfPresent" : node.decodingFunction, accessorPrefix + generatedName(forName: name), node.unwrappedSwiftType.description.appending(".self"), name)]
            }
        }
    }
}

extension SwiftGenerator {
    func renderEncodingBody(forNode node: SpecNode) -> [Syntax] {
        var body: [SyntaxProtocol] = [
            // var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
            generateVariableAssignment(
                letOrVar: .var,
                name: "container",
                type: nil,
                assignment: ExprSyntax(generateFunctionCall(
                    onVariable: "encoder.container",
                    parameters: [.lastParameter(withLabel: "keyedBy", expression: "StringLiteralCodingKey.self")]
                ))
            )
        ]
        
        for encodingNode in inheritedNodes(forNodeName: node.name) + [node] {
            body.append(SyntaxFactory.makeUnknown(""))
            body.append(SyntaxFactory.makeUnknown("// \(encodingNode.name)"))
            
            for encodingExpression in encodingNode.encodingExpressions(typeGroups: nodes) {
                body.append(encodingExpression)
            }
        }
        
        return body.map {
            Syntax.init(fromProtocol: $0).withTrailingTrivia(.newlines(1))
        }
    }
    
    func renderDecodingBody(forNode node: SpecNode) -> [Syntax] {
        var body: [SyntaxProtocol] = [
            // let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
            generateVariableAssignment(
                letOrVar: .let,
                name: "container",
                type: nil,
                assignment: ExprSyntax(generateFunctionCall(
                    onVariable: "try decoder.container",
                    parameters: [.lastParameter(withLabel: "keyedBy", expression: "StringLiteralCodingKey.self")]
                ))
            )
        ]
        
        for decodingNode in inheritedNodes(forNodeName: node.name) + [node] {
            body.append(SyntaxFactory.makeUnknown(""))
            body.append(SyntaxFactory.makeUnknown("// \(decodingNode.name)"))
            
            for decodingExpression in decodingNode.decodingExpressions(typeGroups: nodes) {
                body.append(decodingExpression)
            }
        }
        
        return body.map {
            Syntax.init(fromProtocol: $0).withTrailingTrivia(.newlines(1))
        }
    }
    
    func renderEncodableConformance(forNode node: SpecNode) -> DeclSyntax {
        SyntaxFactory.makeExtension(ofType: node.name, inheritances: ["Codable"], declarations: [
            SyntaxFactory.makeFunction(
                withName: "init",
                specialized: true,
                accessibility: .public,
                signature: SyntaxFactory.makeFunctionSignature(
                    input: SyntaxFactory.makeParameterClause(
                        leftParen: SyntaxFactory.makeLeftParenToken(),
                        parameterList: SyntaxFactory.makeFunctionParameterList([
                            SyntaxFactory.makeFunctionParameter(
                                attributes: nil,
                                firstName: SyntaxFactory.makeIdentifier("from").withTrailingTrivia(.spaces(1)),
                                secondName: SyntaxFactory.makeIdentifier("decoder"),
                                colon: SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)),
                                type: SyntaxFactory.makeTypeIdentifier("Decoder"),
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
                body: SyntaxFactory.makeCodeBlock(
                    leftBrace: SyntaxFactory.makeLeftBraceToken().withTrailingTrivia(.newlines(1)),
                    statements: SyntaxFactory.makeCodeBlockItemList(
                        renderDecodingBody(forNode: node).map {
                            SyntaxFactory.makeCodeBlockItem(item: $0, semicolon: nil, errorTokens: nil).withLeadingTrivia(.tabs(2))
                        }
                    ),
                    rightBrace: SyntaxFactory.makeRightBraceToken().withLeadingTrivia(.tabs(1))
                )
            ).withLeadingTrivia(.tabs(1)).withTrailingTrivia(.newlines(2)),
            SyntaxFactory.makeFunction(
                withName: "encode",
                accessibility: .public,
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
                body: SyntaxFactory.makeCodeBlock(
                    leftBrace: SyntaxFactory.makeLeftBraceToken().withTrailingTrivia(.newlines(1)),
                    statements: SyntaxFactory.makeCodeBlockItemList(
                        renderEncodingBody(forNode: node).map {
                            SyntaxFactory.makeCodeBlockItem(item: $0, semicolon: nil, errorTokens: nil).withLeadingTrivia(.tabs(2))
                        }
                    ),
                    rightBrace: SyntaxFactory.makeRightBraceToken().withLeadingTrivia(.tabs(1))
                )
            ).withLeadingTrivia(.tabs(1))
        ])
    }
    
    func renderEncodableConformances() -> [DeclSyntax] {
        nodes.values.filter { group in
            typeGroup(forName: group.name)?.settings.generationStyle != .abstract
        }.map(renderEncodableConformance(forNode:))
    }
    
    func typeGroup(forName name: String) -> TypeGroup? {
        SpecificationRegistry.shared.query(kind: .typeGroup, name: name) as? TypeGroup
    }
}
