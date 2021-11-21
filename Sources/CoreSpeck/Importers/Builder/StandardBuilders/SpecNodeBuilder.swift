//
//  SpecNodeBuilder.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/14/21.
//

import Foundation

public class SpecNodeBuilder {
    public var parent: SpecBuilder?
    public let node: SpecNode
    
    public init(name: String, parent: SpecBuilder?) {
        self.node = SpecNode(name: name)
        self.parent = parent
    }
    
    public init(name: String, metadata: SpecMetadata?) {
        node = SpecNode(name: name, children: [:], metadata: metadata)
    }
}

extension SpecNodeBuilder: SpecBuilder {
    public var specType: SpecType { node }
    
    public func pushArray(withKey key: String?) throws -> SpecBuilder {
        guard let key = key else {
            throw SpecBuilderError.keyInconsistencyError
        }
        
        let subArray = SpecArrayBuilder(parent: self, key: key)
        node.children[key] = subArray.cluster
        return subArray
    }
    
    public func pushDictionary(withKey key: String?) throws -> SpecBuilder {
        guard let key = key else {
            throw SpecBuilderError.keyInconsistencyError
        }
        
        let subBuilder = SpecNodeBuilder(name: key, parent: self)
        node.children[key] = subBuilder.node
        return subBuilder
    }
    
    public func moveOut() throws -> SpecBuilder {
        parent ?? self
    }
    
    public func pushPrimitive(withType type: SpecPrimitive, key: String?) throws -> SpecBuilder {
        guard let key = key else {
            throw SpecBuilderError.keyInconsistencyError
        }
        
        let subPrimitive = SpecPrimitiveBuilder(type: type, parent: self)
        node.children[key] = subPrimitive.type
        return subPrimitive
    }
}
