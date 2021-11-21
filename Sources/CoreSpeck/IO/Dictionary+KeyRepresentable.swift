//
//  Dictionary+KeyRepresentable.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/20/21.
//

import Foundation

public extension Dictionary {
    subscript<Representable: RawRepresentable>(key: Representable) -> Value? where Representable.RawValue == Key {
        _read {
            yield self[key.rawValue]
        }
        _modify {
            yield &self[key.rawValue]
        }
    }
    
    mutating func removeValue<Representable: RawRepresentable>(forKey key: Representable) where Representable.RawValue == Key {
        removeValue(forKey: key.rawValue)
    }
}

public extension Dictionary.Keys {
    func contains<Representable: RawRepresentable>(_ key: Representable) -> Bool where Representable.RawValue == Key {
        contains(key.rawValue)
    }
}
