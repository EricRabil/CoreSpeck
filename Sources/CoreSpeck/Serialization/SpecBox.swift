//
//  SpecBox.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/14/21.
//

import Foundation
import Yams

/// Abstraction for the dynamic decoding of SpecTypes, powered by SpecificationRegistry
/// You should use the YAMLDecoder/YAMLEncoder APIs instead of using this directly
private struct SpecBox: Codable {
    var spec: SpecType
    
    init(_ spec: SpecType) {
        self.spec = spec
    }
    
    init(from decoder: Decoder) throws {
        spec = try SpecificationRegistry.shared.spec(fromDecoder: decoder)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
        try spec.serialize(to: &container)
    }
}

public extension YAMLDecoder {
    func decode(_ spec: SpecType.Protocol, from data: Data) throws -> SpecType {
        try YAMLDecoder().decode(SpecBox.self, from: data).spec
    }
    
    func decode(_ spec: SpecType.Protocol, from string: String) throws -> SpecType {
        try YAMLDecoder().decode(SpecBox.self, from: string).spec
    }
    
    func decode(_ spec: [String: SpecType].Type, from data: Data) throws -> [String: SpecType] {
        (try YAMLDecoder().decode(from: data) as [String: SpecBox]).mapValues(\.spec)
    }
    
    func decode(_ spec: [String: SpecType].Type, from string: String) throws -> [String: SpecType] {
        (try YAMLDecoder().decode(from: string) as [String: SpecBox]).mapValues(\.spec)
    }
    
    func decode(_ data: Data) throws -> [String: SpecType] {
        try decode([String: SpecType].self, from: data)
    }
    
    func decode(_ string: String) throws -> SpecType {
        try YAMLDecoder().decode(SpecBox.self, from: string).spec
    }
}

public extension YAMLEncoder {
    func encode(_ spec: SpecType) throws -> String {
        try encode(SpecBox(spec))
    }
    
    func encode(_ specs: [String: SpecType]) throws -> String {
        try encode(specs.mapValues(SpecBox.init(_:)))
    }
}
