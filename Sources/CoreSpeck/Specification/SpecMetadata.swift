//
//  SpecMetadata.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/13/21.
//

import Foundation

public final class SpecMetadata: Codable, Equatable {
    public static func == (lhs: SpecMetadata, rhs: SpecMetadata) -> Bool {
        lhs.description == rhs.description &&
        lhs.annotations == rhs.annotations &&
        lhs.hash == rhs.hash
    }
    
    public var description: String?
    public var annotations: [String: String]
    public var hash: String?
    
    public init(description: String?, annotations: [String: String]?) {
        self.description = description
        self.annotations = annotations ?? [:]
    }
    
    public init() {
        self.description = nil
        self.annotations = [:]
        self.hash = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
        
        try container.encodeIfPresent(description, forKey: "description")
        try container.encodeIfPresent(hash, forKey: "hash")
        
        if !annotations.isEmpty {
            try container.encode(annotations, forKey: "annotations")
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
        
        description = try container.decodeIfPresent(String.self, forKey: "description")
        annotations = try container.decodeIfPresent([String: String].self, forKey: "annotations") ?? [:]
        hash = try container.decodeIfPresent(String.self, forKey: "hash")
    }
}

public extension SpecMetadata {
    var isEmpty: Bool {
        if let description = description, description.count > 0 {
            return false
        }
        
        if !annotations.isEmpty {
            return false
        }
        
        if hash != nil {
            return false
        }
        
        return true
    }
}
