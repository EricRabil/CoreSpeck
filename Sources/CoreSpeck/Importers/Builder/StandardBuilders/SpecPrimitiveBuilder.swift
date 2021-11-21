//
//  SpecPrimitiveBuilder.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/14/21.
//

import Foundation

public class SpecPrimitiveBuilder {
    public let type: SpecPrimitive
    public let parent: SpecBuilder
    
    public init(type: SpecPrimitive, parent: SpecBuilder) {
        self.type = type
        self.parent = parent
    }
}

extension SpecPrimitiveBuilder: SpecBuilder {
    public var specType: SpecType { type }
    
    public func pushArray(withKey key: String?) throws -> SpecBuilder {
        throw SpecBuilderError.primitiveAbuseError
    }
    
    public func pushDictionary(withKey key: String?) throws -> SpecBuilder {
        throw SpecBuilderError.primitiveAbuseError
    }
    
    public func moveOut() throws -> SpecBuilder {
        parent
    }
    
    public func pushPrimitive(withType type: SpecPrimitive, key: String?) throws -> SpecBuilder {
        throw SpecBuilderError.primitiveAbuseError
    }
}
