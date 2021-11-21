//
//  SpecEnumeration.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/19/21.
//

import Foundation

public extension SpecKind {
    static let enumeration: SpecKind = "Enumeration"
}

public extension StringLiteralCodingKey {
    static let enumerationKind: StringLiteralCodingKey = "enumerationKind"
    static let cases: StringLiteralCodingKey = "cases"
    static let extensible: StringLiteralCodingKey = "extensible"
}

public class SpecEnumeration {
    /// The name of this enumeration
    public var name: String
    
    /// Whether there are additional, unknown potential values
    public var extensible: Bool
    
    public var metadata: SpecMetadata
    public var enumerationKind: SpecPrimitive.Kind
    public var cases: [String: String]
    
    public init(name: String, extensible: Bool, metadata: SpecMetadata, enumerationKind: SpecPrimitive.Kind, cases: [String : String]) {
        self.name = name
        self.extensible = extensible
        self.metadata = metadata
        self.enumerationKind = enumerationKind
        self.cases = cases
    }
}

extension SpecEnumeration: SpecType, SpecIdentifiable {
    public static var validKinds: [SpecKind] {
        [.enumeration]
    }
    
    public var isPrimitive: Bool {
        false
    }
    
    public var isNode: Bool {
        false
    }
    
    public var isCluster: Bool {
        false
    }
    
    public var isCustomShape: Bool {
        true
    }
    
    public var kind: SpecKind {
        .enumeration
    }
    
    public func isEqual(toType type: SpecType) -> Bool {
        guard let enumeration = type as? SpecEnumeration else {
            return false
        }
        
        return enumeration.name == name &&
                enumeration.cases == cases &&
                enumeration.enumerationKind == enumerationKind
    }
}
