//
//  Codability.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/14/21.
//

import Foundation

public extension KeyedDecodingContainer where Key == StringLiteralCodingKey {
    func spec(forKey key: Key) throws -> SpecType {
        try SpecificationRegistry.shared.spec(fromDecoder: superDecoder(forKey: key))
    }
    
    func decode(_ type: [String: SpecType].Type, forKey key: Key) throws -> [String: SpecType] {
        let container = try superDecoder(forKey: key).container(keyedBy: Key.self)
        
        return try Dictionary(uniqueKeysWithValues: container.allKeys.map { key in
            (
                key.stringValue,
                try container.spec(forKey: key)
            )
        })
    }
}

public extension KeyedEncodingContainer where Key == StringLiteralCodingKey {
    mutating func encode(_ dict: [String: SpecType], forKey key: Key) throws {
        var container = superEncoder(forKey: key).container(keyedBy: Key.self)
        
        for (subkey, subvalue) in dict {
            try container.encode(subvalue, forKey: Key(stringValue: subkey))
        }
    }
    
    mutating func encode(_ type: SpecType, forKey key: Key) throws {
        var container = superEncoder(forKey: key).container(keyedBy: Key.self)
        try type.serialize(to: &container)
    }
}
