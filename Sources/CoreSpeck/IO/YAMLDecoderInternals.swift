//
//  YAMLDecoderInternals.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/15/21.
//

import Foundation
import Yams

private extension KeyedDecodingContainer {
    var mapping: Yams.Node.Mapping {
        Mirror(reflecting: Mirror(reflecting: Mirror(reflecting: self).children.first!.value).children.first!.value).children.map { $0 }.last!.value as! Yams.Node.Mapping
    }
}

internal extension KeyedDecodingContainer {
    func decode(_ node: Node.Type, forKey key: Key) throws -> Node {
        guard let node = mapping[key.stringValue] else {
            throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "Missing key", underlyingError: nil))
        }
        
        return node
    }
}
