//
//  SpecType.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/13/21.
//

import Foundation

public struct SpecError: Error {
    public static func illegalKind(fromDecoder decoder: Decoder) -> SpecError {
        SpecError(reason: "Illegal kind provided to SpecType decoder", codingPath: decoder.codingPath)
    }
    
    public static func illegalKind(fromDecoder decoder: SpecSerializable.SpecDecoder) -> SpecError {
        SpecError(reason: "Illegal kind provided to SpecType decoder", codingPath: decoder.codingPath)
    }
    
    public var reason: String?
    public var codingPath: [CodingKey]?
    
    public init(reason: String?, codingPath: [CodingKey]?) {
        self.reason = reason
        self.codingPath = codingPath
    }
    
    public init(reason: String?) {
        self.reason = reason
        self.codingPath = nil
    }
    
    public init() {
        self.reason = nil
        self.codingPath = nil
    }
}

public protocol SpecType: SpecSerializable, SpecEquatable, SpecHashable {
    static var validKinds: [SpecKind] { get }
    
    var isPrimitive: Bool { get }
    var isCluster: Bool { get }
    var isNode: Bool { get }
    var isCustomShape: Bool { get }
    var kind: SpecKind { get }
    var metadata: SpecMetadata { get }
}

public protocol SpecIdentifiable: SpecType {
    var name: String { get }
}
