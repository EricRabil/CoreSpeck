//
//  SpecBuilder.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/14/21.
//

import Foundation

/// SpecBuilders are an abstraction for scaffolding out a specification while parsing arbitrary data. There is a reference implementation of an XML importer that demonstrates how this can be used.
public protocol SpecBuilder {
    var specType: SpecType { get }
    
    /// Descend into an array builder, optionally keyed depending on your current context
    func pushArray(withKey key: String?) throws -> SpecBuilder
    /// Descend into a dictionary builder, optionally keyed depending on your current context
    func pushDictionary(withKey key: String?) throws -> SpecBuilder
    /// Returns the parent, or self if this is the top
    func moveOut() throws -> SpecBuilder
    /// Descend into a primitive builder, which you should immediately move back out of.
    func pushPrimitive(withType type: SpecPrimitive, key: String?) throws -> SpecBuilder
}

public enum SpecBuilderError: Error {
    /// Thrown when a key is not passed but the builder is a dictionary builder
    case keyInconsistencyError
    /// Thrown when a key is passed but the builder is an array builder
    case arrayInconsistencyError
    /// Thrown when attempting to write to a primitive builder. You should move back out of it, it is a terminal point.
    case primitiveAbuseError
}
