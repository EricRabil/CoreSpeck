//
//  CustomizationSerializable.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/15/21.
//

import Foundation
import Yams

private extension StringLiteralCodingKey {
    static let operation: StringLiteralCodingKey = "op"
    static let path: StringLiteralCodingKey = "path"
    static let value: StringLiteralCodingKey = "value"
    static let hashes: StringLiteralCodingKey = "hashes"
    static let target: StringLiteralCodingKey = "target"
    static let patches: StringLiteralCodingKey = "patches"
    static let missingBehavior: StringLiteralCodingKey = "missing-behavior"
}

extension SpecCustomization: SpecSerializable {
    public static func spec(withKind kind: SpecKind, from decoder: SpecDecoder) throws -> SpecType {
        SpecCustomization (
            target: try decoder.decode(CustomizationTarget.self, forKey: .target),
            patches: try decoder.decode([CustomizationPatch].self, forKey: .patches),
            name: try decoder.decode(String.self, forKey: .name)
        )
    }
    
    public func serialize(to encoder: inout SpecEncoder) throws {
        try encoder.encode(target, forKey: .target)
        try encoder.encode(patches, forKey: .patches)
        try encoder.encode(name, forKey: .name)
    }
}

extension CustomizationTarget: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
        
        kind = try container.decodeIfPresent(String.self, forKey: .kind)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        metadata = try container.decodeIfPresent(SpecMetadata.self, forKey: .metadata)
        hashes = try container.decodeIfPresent([String].self, forKey: .hashes)
        
        do {
            if let rawChildren = try container.decodeIfPresent(String.self, forKey: .nodeChildren) {
                children = [try Yams.compose(yaml: rawChildren)!.mapping!]
            }
        } catch {
            if let rawChildren = try container.decodeIfPresent([String].self, forKey: .nodeChildren) {
                children = try rawChildren.map {
                    try Yams.compose(yaml: $0)!.mapping!
                }
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
        
        if let kind = kind {
            try container.encode(kind, forKey: .kind)
        }
        
        if let name = name {
            try container.encode(name, forKey: .name)
        }
        
        if let metadata = metadata {
            try container.encode(metadata, forKey: .metadata)
        }
        
        if let hashes = hashes {
            try container.encode(hashes, forKey: .hashes)
        }
        
        if let children = children, !children.isEmpty {
            if children.count == 1 {
                try container.encode(try Yams.serialize(node: Node.mapping(children[0])), forKey: .nodeChildren)
            } else {
                try container.encode(try children.map {
                    try Yams.serialize(node: Node.mapping($0))
                }, forKey: .nodeChildren)
            }
        }
    }
}

extension CustomizationPatch: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
        
        operation = try container.decode(PatchType.self, forKey: .operation)
        path = try container.decode(String.self, forKey: .path)
        metadata = try container.decodeIfPresent(SpecMetadata.self, forKey: .metadata) ?? SpecMetadata()
        missingBehavior = try container.decodeIfPresent(MissingBehavior.self, forKey: .missingBehavior) ?? .throw
        
        switch operation {
        case .add: fallthrough
        case .replace: fallthrough
        case .append:
            value = try container.decode(Node.self, forKey: .value)
        default:
            break
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
        
        try container.encode(operation, forKey: .operation)
        try container.encode(path, forKey: .path)
        
        if missingBehavior == .skip {
            try container.encode(missingBehavior, forKey: .missingBehavior)
        }
        
        if !metadata.isEmpty {
            try container.encode(metadata, forKey: .metadata)
        }
        
        if let value = value {
            try container.encode(Yams.serialize(node: value), forKey: .value)
        }
    }
}
