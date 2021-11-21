//
//  TypeGroup.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/16/21.
//

import Foundation

public extension SpecKind {
    static let typeGroup: SpecKind = "TypeGroup"
}

/// TypeGroup is a sidecar for root SpecNodes, and its name is equivalent to the SpecNode name it targets. It allows authors to provide additional metadata to generators, and to specialize code synthesis.
/// TypeGroups do not, and will never, affect type mashing. They are solely meant to influence how code is generated.
public class TypeGroup {
    public enum GenerationStyle: String, Codable {
        case concrete = "Concrete"
        case abstract = "Abstract"
    }
    
    public struct Settings: Codable {
        public var generationStyle: GenerationStyle
        public var explicitlyExtends: [String]
        
        public init() {
            generationStyle = .concrete
            explicitlyExtends = []
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
            
            generationStyle = try container.decodeIfPresent(GenerationStyle.self, forKey: "generationStyle") ?? .concrete
            explicitlyExtends = try container.decodeIfPresent([String].self, forKey: "explicitlyExtends") ?? []
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
            
            try container.encode(generationStyle, forKey: "generationStyle")
            
            if !explicitlyExtends.isEmpty {
                try container.encode(explicitlyExtends, forKey: "explicitlyExtends")
            }
        }
        
        var isEmpty: Bool {
            true
        }
    }
    
    public var name: String
    public var settings: Settings
    public var metadata: SpecMetadata
    
    public init(name: String, settings: Settings, metadata: SpecMetadata) {
        self.name = name
        self.settings = settings
        self.metadata = metadata
    }
    
    public init(name: String) {
        self.name = name
        self.settings = Settings()
        self.metadata = SpecMetadata()
    }
}

extension TypeGroup: SpecType, SpecIdentifiable {
    public static var validKinds: [SpecKind] {
        [.typeGroup]
    }
    
    public var isCluster: Bool {
        false
    }
    
    public var isPrimitive: Bool {
        false
    }
    
    public var isNode: Bool {
        false
    }
    
    public var isCustomShape: Bool {
        true
    }
    
    public var kind: SpecKind {
        .typeGroup
    }
}

extension TypeGroup: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        kind.specHash(into: &hasher)
        name.specHash(into: &hasher)
    }
}

extension TypeGroup: SpecEquatable {
    public func isEqual(toType type: SpecType) -> Bool {
        guard let spec = type as? TypeGroup else {
            return false
        }
        
        return spec.name == name
    }
}

extension TypeGroup: SpecSerializable {
    public static func spec(withKind kind: SpecKind, from decoder: SpecDecoder) throws -> SpecType {
        TypeGroup (
            name: try decoder.decode(String.self, forKey: .name),
            settings: try decoder.decodeIfPresent(Settings.self, forKey: "settings") ?? Settings(),
            metadata: try decoder.decodeIfPresent(SpecMetadata.self, forKey: .metadata) ?? SpecMetadata()
        )
    }
    
    public func serialize(to encoder: inout SpecEncoder) throws {
        try encoder.encode(name, forKey: .name)
        
        if !settings.isEmpty {
            try encoder.encode(settings, forKey: "settings")
        }
        
        if !metadata.isEmpty {
            try encoder.encode(metadata, forKey: .metadata)
        }
    }
}
