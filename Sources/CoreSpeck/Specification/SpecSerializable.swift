//
//  SpecSerializable.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/14/21.
//

import Foundation

public protocol SpecSerializable {
    typealias SpecDecoder = KeyedDecodingContainer<StringLiteralCodingKey>
    typealias SpecEncoder = KeyedEncodingContainer<StringLiteralCodingKey>
    
    static func spec(withKind kind: SpecKind, from decoder: SpecDecoder) throws -> SpecType
    func serialize(to encoder: inout SpecEncoder) throws
}
