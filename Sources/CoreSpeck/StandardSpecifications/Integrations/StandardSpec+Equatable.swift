//
//  StandardSpec+Equatable.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/14/21.
//

import Foundation

extension SpecPrimitive: SpecEquatable {
    public func isEqual(toType type: SpecType) -> Bool {
        guard type.kind == kind, let primitive = type as? SpecPrimitive else {
            return false
        }
        
        return primitive.primitiveKind == primitiveKind
    }
}

extension SpecCluster: SpecEquatable {
    public func isEqual(toType type: SpecType) -> Bool {
        guard type.kind == kind, let cluster = type as? SpecCluster else {
            return false
        }
        
        guard element.isEqual(toType: cluster.element) else {
            return false
        }
        
        if let key = key {
            guard let otherKey = cluster.key else {
                return false
            }
            
            guard key.isEqual(toType: otherKey) else {
                return false
            }
        }
        
        return true
    }
}

extension SpecNode: SpecEquatable {
    public func isEqual(toType type: SpecType) -> Bool {
        guard type.kind == kind, let node = type as? SpecNode else {
            return false
        }
        
        guard children.keys == node.children.keys else {
            return false
        }
        
        for (key, value) in children {
            guard let child = node.children[key] else {
                return false
            }
            
            guard value.isEqual(toType: child) else {
                return false
            }
        }
        
        return true
    }
}

extension SpecAlias: SpecEquatable {
    public func isEqual(toType type: SpecType) -> Bool {
        guard type.kind == kind, let alias = type as? SpecAlias else {
            return false
        }
        
        return aliasedName == alias.aliasedName && aliasedKind == alias.aliasedKind
    }
}

extension SpecCustomization: SpecEquatable {
    public func isEqual(toType type: SpecType) -> Bool {
        (type as? SpecCustomization) == self
    }
}
