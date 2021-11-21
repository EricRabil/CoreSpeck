//
//  SpecificationRegistry.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/13/21.
//

import Foundation
import Yams

// Uniquely identifiers a spec by Kind-ID
// This implies that only one spec with a given kind+ID may exist, and this is asserted throughout the code.
public enum SpecTag: Hashable {
    case tag(kind: SpecKind, id: String)
    
    private var bits: (kind: String, id: String) {
        _read {
            yield unsafeBitCast(self, to: (kind: String, id: String).self)
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        let (kind, id) = bits
        kind.hash(into: &hasher)
        id.hash(into: &hasher)
    }
}

public class SpecificationRegistry {
    public static let shared = SpecificationRegistry()
    private init() {
        // bootstrap the registry with the standard specs
        register(specType: SpecPrimitive.self) {}
        register(specType: SpecCluster.self) {}
        register(specType: SpecNode.self) {}
        register(specType: SpecAlias.self) {}
        register(specType: SpecCustomization.self) {}
        register(specType: TypeGroup.self) {}
        register(specType: SpecEnumeration.self) {}
    }
    
    public var types: [SpecKind: SpecType.Type] = [:]
    public private(set) var specs: [SpecTag: SpecIdentifiable] = [:]
    
    private func register<P: SpecType>(specType: P.Type, onCollission: () throws -> ()) rethrows {
        for kind in specType.validKinds {
            if types.keys.contains(kind) {
                try onCollission()
            }
            
            types[kind] = specType
        }
    }
    
    public func loadRecursively(fromURL url: URL) throws {
        try FileManager.default.enumerator(at: url).enumerate { url in
            guard url.pathExtension == "yml" || url.pathExtension == "yaml" else {
                return
            }
            
            for part in try decodeMany(fromYaml: String(contentsOf: url)) {
                if let identifiable = part as? SpecIdentifiable {
                    specs[.tag(kind: identifiable.kind, id: identifiable.name)] = identifiable
                }
            }
        }
    }
    
    public func register<P: SpecType>(specType: P.Type) throws {
        try register(specType: specType) {
            throw SpecError(reason: "Specs declare overlapping kinds. This is illegal and you will be killed.")
        }
    }
    
    public func spec(fromDecoder decoder: Decoder) throws -> SpecType {
        let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
        
        let kind = try container.decode(SpecKind.self, forKey: .kind)
        
        guard let type = types[kind] else {
            throw SpecError(reason: "Unknown kind '\(kind)' encountered", codingPath: decoder.codingPath)
        }
        
        return try type.spec(withKind: kind, from: container)
    }
}

public extension SpecificationRegistry {
    func query(kind: SpecKind, name: String) -> SpecType? {
        specs[.tag(kind: kind, id: name)]
    }
}

public extension SpecificationRegistry {
    enum SpecDecodingError: Error {
        case parseResultNil
    }
    
    private func split(yaml: String) throws -> [String] {
        try Yams.compose_all(yaml: yaml).map { node in
            try Yams.serialize(node: node)
        }
    }
    
    func decodeMany(fromYaml yaml: String) throws -> [SpecType] {
        try split(yaml: yaml).map(decodeSpec(fromYaml:))
    }
    
    func decodeSpec(fromYaml yaml: String) throws -> SpecType {
        try YAMLDecoder().decode(SpecType.self, from: yaml)
    }
    
    func decodeSpecs(fromYaml yaml: String) throws -> [String: SpecType] {
        try YAMLDecoder().decode([String: SpecType].self, from: yaml)
    }
    
    func decodeSpec(fromYaml yaml: Data) throws -> SpecType {
        try YAMLDecoder().decode(SpecType.self, from: yaml)
    }
    
    func decodeSpecs(fromYaml yaml: Data) throws -> [String: SpecType] {
        try YAMLDecoder().decode([String: SpecType].self, from: yaml)
    }
    
    func encodeSpec(toYaml spec: SpecType) throws -> String {
        try YAMLEncoder().encode(spec)
    }
    
    func encodeSpec(toYamlData spec: SpecType) throws -> Data {
        Data(try YAMLEncoder().encode(spec).utf8)
    }
}

public extension SpecificationRegistry {
    enum SpecStorageError: Error {
        case unidentifiable
    }
    
    func store(spec: SpecType) throws -> SpecIdentifiable? {
        guard let spec = spec as? SpecIdentifiable else {
            throw SpecStorageError.unidentifiable
        }
        
        return store(spec: spec)
    }
    
    @discardableResult
    func store(spec: SpecIdentifiable) -> SpecIdentifiable? {
        specs.updateValue(spec, forKey: spec.tag)
    }
}

private extension SpecIdentifiable {
    @_transparent
    var tag: SpecTag {
        .tag(kind: kind, id: name)
    }
}
