//
//  SpecCluster.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/13/21.
//

import Foundation

public enum SpecCluster {
    case array(element: SpecType, metadata: SpecMetadata)
    case dictionary(key: SpecType, element: SpecType, metadata: SpecMetadata)
    
    @inlinable public var isArray: Bool {
        switch self {
        case .array: return true
        case .dictionary: return false
        }
    }
    
    @inlinable public var isDictionary: Bool {
        switch self {
        case .array: return false
        case .dictionary: return true
        }
    }
    
    @inlinable public var metadata: SpecMetadata {
        get {
            switch self {
            case .array(_,let metadata): return metadata
            case .dictionary(_,_,let metadata): return metadata
            }
        }
        set {
            switch self {
            case .array: self = .array(element: element, metadata: newValue)
            case .dictionary(let key, let element, _): self = .dictionary(key: key, element: element, metadata: newValue)
            }
        }
    }
    
    @inlinable public var element: SpecType {
        get {
            switch self {
            case .array(let element,_): return element
            case .dictionary(_, let element,_): return element
            }
        }
        set {
            switch self {
            case .array(_, let metadata): self = .array(element: newValue, metadata: metadata)
            case .dictionary(let key,_,let metadata): self = .dictionary(key: key, element: newValue, metadata: metadata)
            }
        }
    }
    
    @inlinable public var key: SpecType? {
        get {
            switch self {
            case .array: return nil
            case .dictionary(let key, _,_): return key
            }
        }
        set {
            if let newValue = newValue {
                self = .dictionary(key: newValue, element: element, metadata: metadata)
            } else {
                self = .array(element: element, metadata: metadata)
            }
        }
    }
}

internal extension SpecType {
    var isCluster: Bool {
        self is SpecCluster
    }
    
    var isArray: Bool {
        (self as? SpecCluster)?.isArray ?? false
    }
    
    var isDictionary: Bool {
        (self as? SpecCluster)?.isDictionary ?? false
    }
}

extension SpecCluster: SpecType {
    public static var validKinds: [SpecKind] { [ .array, .dictionary ] }
    
    public var isPrimitive: Bool { false }
    public var isCluster: Bool { true }
    public var isNode: Bool { false }
    public var isCustomShape: Bool { false }
    
    public var kind: SpecKind {
        switch self {
        case .array: return .array
        case .dictionary: return .dictionary
        }
    }
}
