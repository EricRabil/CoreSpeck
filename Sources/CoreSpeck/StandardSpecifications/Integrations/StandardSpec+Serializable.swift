//
//  StandardSpec+Serializable.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/14/21.
//

import Foundation

internal extension StringLiteralCodingKey {
    static let kind: StringLiteralCodingKey = "kind"
    static let name: StringLiteralCodingKey = "name"
    static let metadata: StringLiteralCodingKey = "metadata"
    static let aliasedName: StringLiteralCodingKey = "aliasedName"
    static let nodeChildren: StringLiteralCodingKey = "children"
    static let primitiveType: StringLiteralCodingKey = "type"
    static let clusterElement: StringLiteralCodingKey = "element"
    static let clusterKey: StringLiteralCodingKey = "key"
    static let hash: StringLiteralCodingKey = "hash"
    static let aliasedKind: StringLiteralCodingKey = "aliasedKind"
}

extension SpecPrimitive: SpecSerializable {
    public static func spec(withKind kind: SpecKind, from decoder: SpecDecoder) throws -> SpecType {
        SpecPrimitive (
            kind: try decoder.decode(SpecPrimitive.Kind.self, forKey: .primitiveType),
            metadata: try decoder.decodeIfPresent(SpecMetadata.self, forKey: .metadata) ?? SpecMetadata()
        )
    }
    
    public func serialize(to encoder: inout KeyedEncodingContainer<StringLiteralCodingKey>) throws {
        try encoder.encode(kind, forKey: .kind)
        try encoder.encode(primitiveKind.rawValue, forKey: .primitiveType)
        
        if !metadata.isEmpty {
            try encoder.encode(metadata, forKey: .metadata)
        }
    }
}

extension SpecCluster: SpecSerializable {
    public static func spec(withKind kind: SpecKind, from decoder: SpecDecoder) throws -> SpecType {
        switch kind {
        case .array:
            return SpecCluster.array (
                element: try decoder.spec(forKey: .clusterElement),
                metadata: try decoder.decodeIfPresent(SpecMetadata.self, forKey: .metadata) ?? SpecMetadata()
            )
        case .dictionary:
            return SpecCluster.dictionary (
                key: try decoder.spec(forKey: .clusterKey),
                element: try decoder.spec(forKey: .clusterElement),
                metadata: try decoder.decodeIfPresent(SpecMetadata.self, forKey: .metadata) ?? SpecMetadata()
            )
        default:
            throw SpecError.illegalKind(fromDecoder: decoder)
        }
    }
    
    public func serialize(to encoder: inout SpecEncoder) throws {
        try encoder.encode(kind, forKey: .kind)
        
        if !metadata.isEmpty {
            try encoder.encode(metadata, forKey: .metadata)
        }
        
        if let key = key {
            try encoder.encode(key, forKey: .clusterKey)
        }
        
        try encoder.encode(element, forKey: .clusterElement)
    }
}

extension SpecNode: SpecSerializable {
    public static func spec(withKind kind: SpecKind, from decoder: SpecDecoder) throws -> SpecType {
        SpecNode (
            name: try decoder.decode(String.self, forKey: .name),
            children: try decoder.decode([String: SpecType].self, forKey: .nodeChildren),
            metadata: try? decoder.decode(SpecMetadata.self, forKey: .metadata)
        )
    }
    
    public func serialize(to encoder: inout SpecEncoder) throws {
        try encoder.encode(kind, forKey: .kind)
        try encoder.encode(name, forKey: .name)
        
        if !metadata.isEmpty {
            try encoder.encode(metadata, forKey: .metadata)
        }
        
        try encoder.encode(children, forKey: .nodeChildren)
    }
}

extension SpecAlias: SpecSerializable {
    public static func spec(withKind kind: SpecKind, from decoder: SpecDecoder) throws -> SpecType {
        SpecAlias (
            name: try decoder.decode(String.self, forKey: .name),
            aliasedName: try decoder.decode(String.self, forKey: .aliasedName),
            aliasedKind: try decoder.decode(SpecKind.self, forKey: .aliasedKind),
            metadata: try? decoder.decode(SpecMetadata.self, forKey: .metadata)
        )
    }
    
    public func serialize(to encoder: inout SpecEncoder) throws {
        try encoder.encode(kind, forKey: .kind)
        try encoder.encode(name, forKey: .name)
        
        if !metadata.isEmpty {
            try encoder.encode(metadata, forKey: .metadata)
        }
        
        try encoder.encode(aliasedName, forKey: .aliasedName)
        try encoder.encode(aliasedKind, forKey: .aliasedKind)
    }
}

extension SpecEnumeration: SpecSerializable {
    public static func spec(withKind kind: SpecKind, from decoder: SpecDecoder) throws -> SpecType {
        SpecEnumeration (
            name: try decoder.decode(String.self, forKey: .name),
            extensible: try decoder.decodeIfPresent(Bool.self, forKey: .extensible) ?? false,
            metadata: try decoder.decodeIfPresent(SpecMetadata.self, forKey: .metadata) ?? SpecMetadata(),
            enumerationKind: try decoder.decode(SpecPrimitive.Kind.self, forKey: .enumerationKind),
            cases: try decoder.decode([String: String].self, forKey: .cases)
        )
    }
    
    public func serialize(to encoder: inout SpecEncoder) throws {
        try encoder.encode(kind, forKey: .kind)
        try encoder.encode(name, forKey: .name)
        try encoder.encode(extensible, forKey: .extensible)
        
        if !metadata.isEmpty {
            try encoder.encode(metadata, forKey: .metadata)
        }
        
        try encoder.encode(enumerationKind, forKey: .enumerationKind)
        try encoder.encode(cases, forKey: .cases)
    }
}
