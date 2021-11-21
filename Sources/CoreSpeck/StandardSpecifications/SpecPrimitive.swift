//
//  SpecPrimitive.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/13/21.
//

import Foundation

/// Lowest-level representation a spec can yield
public enum SpecPrimitive {
    case string(SpecMetadata)
    case integer(SpecMetadata)
    case double(SpecMetadata)
    case bool(SpecMetadata)
    case never(SpecMetadata)
    case date(SpecMetadata)
    case data(SpecMetadata)
    
    public init(kind: Kind, metadata: SpecMetadata) {
        switch kind {
        case .string: self = .string(metadata)
        case .integer: self = .integer(metadata)
        case .double: self = .double(metadata)
        case .bool: self = .bool(metadata)
        case .never: self = .never(metadata)
        case .date: self = .date(metadata)
        case .data: self = .data(metadata)
        }
    }
    
    public init(kind: Kind) {
        self.init(kind: kind, metadata: SpecMetadata())
    }
    
    public init?(rawValue: String, metadata: SpecMetadata) {
        guard let kind = Kind(rawValue: rawValue) else {
            return nil
        }
        
        self.init(kind: kind, metadata: metadata)
    }
    
    public init?(rawValue: String) {
        self.init(rawValue: rawValue, metadata: SpecMetadata())
    }
    
    public enum Kind: String, Codable {
        case string = "String"
        case integer = "Integer"
        case double = "Double"
        case bool = "Boolean"
        case never = "Never"
        case date = "Date"
        case data = "Data"
    }
    
    public var metadata: SpecMetadata {
        get {
            switch self {
            case .string(let metadata): return metadata
            case .integer(let metadata): return metadata
            case .double(let metadata): return metadata
            case .bool(let metadata): return metadata
            case .never(let metadata): return metadata
            case .date(let metadata): return metadata
            case .data(let metadata): return metadata
            }
        }
        set {
            switch self {
            case .string: self = .string(newValue)
            case .integer: self = .integer(newValue)
            case .double: self = .double(newValue)
            case .bool: self = .bool(newValue)
            case .never: self = .never(newValue)
            case .date: self = . date(newValue)
            case .data: self = .data(newValue)
            }
        }
    }
    
    public var primitiveKind: Kind {
        get {
            switch self {
            case .string: return .string
            case .integer: return .integer
            case .double: return .double
            case .bool: return .bool
            case .never: return .never
            case .date: return .date
            case .data: return .data
            }
        }
        set {
            switch newValue {
            case .string: self = .string(metadata)
            case .integer: self = .integer(metadata)
            case .double: self = .double(metadata)
            case .bool: self = .bool(metadata)
            case .never: self = .never(metadata)
            case .date: self = .date(metadata)
            case .data: self = .data(metadata)
            }
        }
    }
}

extension SpecPrimitive: SpecType {
    public static var validKinds: [SpecKind] {
        [.primitive]
    }
    
    public var isPrimitive: Bool { true }
    public var isCluster: Bool { false }
    public var isNode: Bool { false }
    public var isCustomShape: Bool { false }
    
    public var kind: SpecKind {
        .primitive
    }
}
