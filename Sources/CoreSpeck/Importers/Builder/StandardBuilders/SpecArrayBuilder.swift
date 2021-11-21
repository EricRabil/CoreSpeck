//
//  SpecArrayBuilder.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/14/21.
//

import Foundation

public class SpecArrayBuilder {
    public var parent: SpecBuilder
    public var cluster: SpecCluster
    
    private var superKey: String? = nil
    private var sealed = false
    
    public init(parent: SpecBuilder) {
        self.parent = parent
        self.cluster = .array(element: SpecPrimitive(kind: .never), metadata: SpecMetadata())
    }
    
    internal init(parent: SpecNodeBuilder, key: String) {
        self.parent = parent
        self.superKey = key
        self.cluster = .array(element: SpecPrimitive(kind: .never), metadata: SpecMetadata())
    }
}

extension SpecArrayBuilder: SpecBuilder {
    public var specType: SpecType { cluster }
    
    public func pushArray(withKey key: String?) throws -> SpecBuilder {
        guard sealed ? cluster.element.isArray : true else {
            throw SpecBuilderError.arrayInconsistencyError
        }
        
        let subArray = SpecArrayBuilder(parent: self)
        cluster.element = subArray.cluster
        sealed = true
        return subArray
    }
    
    public func pushDictionary(withKey key: String?) throws -> SpecBuilder {
        guard sealed ? cluster.element.isDictionary : true else {
            throw SpecBuilderError.arrayInconsistencyError
        }
        
        let subNode = SpecNodeBuilder(name: UUID().uuidString, parent: self)
        cluster.element = subNode.node
        sealed = true
        return subNode
    }
    
    public func moveOut() throws -> SpecBuilder {
        if let parent = parent as? SpecArrayBuilder {
            parent.cluster.element = cluster
        } else if let parent = parent as? SpecNodeBuilder, let key = superKey {
            parent.node.children[key] = cluster
        }
        
        return parent
    }
    
    public func pushPrimitive(withType type: SpecPrimitive, key: String?) throws -> SpecBuilder {
        guard sealed ? cluster.element.isPrimitive : true else {
            throw SpecBuilderError.arrayInconsistencyError
        }
        
        let subPrimitive = SpecPrimitiveBuilder(type: type, parent: self)
        cluster.element = subPrimitive.type
        sealed = true
        
        return subPrimitive
    }
}
