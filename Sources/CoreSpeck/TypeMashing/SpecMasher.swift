//
//  SpecMasher.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/19/21.
//

import Foundation

/*
 The SpecMasher consumes a set of potentially overlapping types, deep-merging their YAML structures by (kind:name), then processes annotations.
 
 Mashing is performed through a recursive ingestion of nodes, and processes extracted-type annotations during initial ingestion.
 For the purposes of readability, extracted types will be referred to as lifted types throughout this docblock.
 
 Lifted types are stored as regular nodes, indistinguishable from nodes you pass via eat(nodes:). Their use case is to reduce the depth of nodes, as well as create depth-0 nodes from nested nodes for languages that do not easily support such structures (Swift, for example, does not have stellar support for nested types. Instead, you define a set of nodes, and interleave them within eachother.
 
 Synthesized aggregates are a mechanism in which you can lift a group of properties out into a single type, but still expect them to be de/serialized in the same tier as their parent.
 */
open class SpecMasher {
    fileprivate let _masher = _TypeMasher()
    
    public init() {}
    
    public func eat(nodes: [SpecNode]) {
        _masher.eat(nodes: nodes)
    }
}

// MARK: - Querying

// Structures
public extension SpecMasher {
    var types: [String: SpecIdentifiable] {
        _masher.declaredTypes
    }
    
    var nodes: [String: SpecNode] {
        types.compactMapValues {
            $0 as? SpecNode
        }
    }
    
    var enums: [String: SpecEnumeration] {
        types.compactMapValues {
            $0 as? SpecEnumeration
        }
    }
    
    var aliases: [String: SpecAlias] {
        types.compactMapValues {
            $0 as? SpecAlias
        }
    }
}

// Inheritance
public extension SpecMasher {
    /// Type groups with a sidecar resource (aptly named TypeGroup) can specify a list of type groups in explicitlyExtends, which is implementing an interface.
    /// This has the effect of recursively importing all of the nodes of said groups, and should be propagated to serialization and structure definitions.
    func inheritedNodes(forNodeName name: String) -> [SpecNode] {
        let typeGroupDefs = (SpecificationRegistry.shared.query(kind: .typeGroup, name: name) as? TypeGroup) ?? TypeGroup(name: name)
        
        return typeGroupDefs.settings.explicitlyExtends.compactMap {
            nodes[$0]
        }
    }
    
    /// Returns an array of potentially overlapping properties inherited by a node name. It is your responsibility to either resolve or reject any collisions.
    func inheritedProperties(forNodeName name: String) -> [(String, SpecType)] {
        inheritedNodes(forNodeName: name).flatMap {
            $0.children
        }
    }
}
