//
//  SpecType+Inheritance.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/20/21.
//

import Foundation

public extension SpecType {
    func makeAlias(withName name: String, inheritingMetadata: SpecType) -> SpecAlias {
        let alias = SpecAlias(name: name, aliasedName: name, aliasedKind: kind)
        alias.inheritMetadata(fromSpec: inheritingMetadata)
        
        return alias
    }
    
    func makeAlias(withName name: String) -> SpecAlias {
        makeAlias(withName: name, inheritingMetadata: self)
    }
}

public extension SpecType where Self: SpecIdentifiable {
    func makeAlias(inheritingMetadata: SpecType) -> SpecAlias {
        makeAlias(withName: name, inheritingMetadata: inheritingMetadata)
    }
    
    func makeAlias() -> SpecAlias {
        makeAlias(inheritingMetadata: self)
    }
}

public extension SpecType {
    func inheritMetadata(fromSpec spec: SpecType) {
        metadata.description = spec.metadata.description
        metadata.annotations = spec.metadata.annotations
    }
    
    func stripAnnotations(withKeys keys: [String]) {
        for key in keys {
            metadata.annotations.removeValue(forKey: key)
        }
    }
    
    func stripAnnotations(withKeys keys: [AnnotationKey]) {
        stripAnnotations(withKeys: keys.map(\.rawValue))
    }
}
