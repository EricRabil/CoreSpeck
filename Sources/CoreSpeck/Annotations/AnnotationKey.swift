//
//  AnnotationKey.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/20/21.
//

import Foundation

public struct AnnotationKey: ExpressibleByStringLiteral, RawRepresentable, Hashable {
    public var rawValue: String
    
    public typealias StringLiteralType = String
    public typealias RawValue = String
    
    public init(stringLiteral value: String) {
        rawValue = value
    }
    
    public init(rawValue: String) {
        self.init(stringLiteral: rawValue)
    }
}

public extension AnnotationKey {
    static let readableName: String = "ericrabil.com/readable-name"
    static let requireConstant: String = "ericrabil.com/require-constant"
    static let nullable: String = "ericrabil.com/value-nullable"
    static let generationFormat: String = "ericrabil.com/generation-format"
    static let synthesizedAggregate: String = "ericrabil.com/synthesized-aggregate"
}
