//
//  _TypeMasher.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/16/21.
//

import Foundation

/// Assists in performing computations for producing cohesive typedefs that can then go to a generator. Due to its complexity it is wrapped by a public-facing class that has minimal control over internal operations
internal class _TypeMasher: AnnotationProcessorDelegate, _PrivateAnnotationProcessorDelegate {
    // typeGroupAggregates captures all occurances of all properties that identify with a type group. A closure is used to safely track changes to the property while still capturing it
    private var typeGroupAggregates: [String: [String: [() -> SpecType]]] = [:]
    
    /// A set of type groups compiled from aggregates. You can consider this the central point for API definitions
    private(set) var declaredTypes: [String: SpecIdentifiable] = [:]
    
    // [ extracted name : [ spec that outlines a shape of extracted type ] ]
    // your goal is to flatten this into a single spec that represents all of the potential shapes
    // this is treated as a buffer, and it is drained as part of the mashing pass until it is not refilled during a pass.
    // nodes here will be picked up in the flattening pass, and then they will be pushed as if they were a root node
    private var extractedNodes: [String: [SpecNode]] = [:]
    
    // nodes picked up from extractedNodes will be pushed here, where they are then drained and pushed as if they were a root node
    private var flattenedTypeExtractions: [String: SpecNode] = [:]
    
    init() {}
    
    private func reset() {
        typeGroupAggregates = [:]
        extractedNodes = [:]
        flattenedTypeExtractions = [:]
        declaredTypes = [:]
    }
    
    func eat(nodes: [SpecNode]) {
        reset()
        
        AnnotationRegistry.shared.delegate = self
        
        // push the root nodes to kick off the passes
        for node in nodes {
            push(root: node.clone())
        }
        
        // repeatedly mash together encountered type groups until they stop showing up
        while !extractedNodes.isEmpty {
            // drain extractedNodes, mapping each pair to a flattened type group
            while !extractedNodes.isEmpty {
                let (typeName, extractedTypes) = extractedNodes.remove(at: extractedNodes.startIndex)
                flattenedTypeExtractions[typeName] = createFlattenedNode(named: typeName, nodes: extractedTypes, base: flattenedTypeExtractions[typeName])
            }
            
            // ingest all new flattened type groups
            while !flattenedTypeExtractions.isEmpty {
                push(root: flattenedTypeExtractions.remove(at: flattenedTypeExtractions.startIndex).value)
            }
        }
        
        for (groupName, groupChildren) in typeGroupAggregates {
            declaredTypes[groupName] = assembleTypeGroup(named: groupName, children: groupChildren)
        }
        
        // un-delegate ourselves from the registry.
        // TODO: make each masher have its own registry? it'd be nice to let people plug in their own annotations.
        AnnotationRegistry.shared.delegate = nil
    }
    
    func processor<SpecType>(_ processor: AnnotationProcessor, createdSpec spec: SpecType) where SpecType : SpecIdentifiable {
        switch spec {
        case let spec as SpecNode:
            extractedNodes[spec.name, default: []].append(spec)
        default:
            declaredTypes[spec.name] = spec
        }
    }
    
    func processor(_ processor: AnnotationProcessor, foundSpec spec: @escaping @autoclosure () -> SpecType, named name: String, inTypeGroup typeGroup: String) {
        typeGroupAggregates[typeGroup, default: [:]][name, default: []].append(spec)
    }
}

fileprivate extension _TypeMasher {
    /// Feeds a type into the annotation processor, and then stores it into the declared types if it is eligible to be a root type
    func push(root: SpecNode) {
        guard let root = AnnotationRegistry.shared.process(spec: root) as? SpecIdentifiable else {
            // an annotation processor rejected the node, and we will not process it further.
            return
        }
        
        switch root {
        case is SpecNode:
            // a root node can be directly inserted if and only if it declares "ericrabil.com/root-type" to be true.
            if root.metadata.annotations["ericrabil.com/root-type"] != "true" {
                break
            }
            
            fallthrough
        default:
            declaredTypes[root.name] = root
        }
    }
}

/*
 Type group assembly:
 
 Customizations label designated attributes as members of a type group, and if you have a large data set (as you should), you're going to get some duplicates with (hopefully) different structures. This algorithm merges the different structures together with a traditional deep merging algorithm, producing a single type that intends to represent all of the encountered types for a given type group property.
 
 After all properties are merged, a new SpecNode is returned that represents an aggregation of the children argument
 */

/// Deep-merges a collection of samples for each property associated with a type group, and then inserts them into a new SpecNode. The returned SpecNode will be named the first argument.
internal func assembleTypeGroup(named typeGroupName: String, children: [String: [() -> SpecType]]) -> SpecNode {
    let node = SpecNode(name: typeGroupName)
    
    for (childName, childSamples) in children {
        var childSamples = childSamples // mutable copy
        
        // if its empty, continue
        guard !childSamples.isEmpty else {
            continue
        }
        
        // flatten the childSamples using deep-merge from left to right
        // note the curried call to removeFirst - remember that type group samples are stored as closures so we can have a reference type instead of value type
        // this is because not all spec types are guaranteed to be classes, and the stdspec provides some value types
        let mergedSample = childSamples.reduce(childSamples.removeFirst()()) { sample, nextSample in
            sample.merge(withNode: nextSample())
        }
        
        node.children[childName] = mergedSample
    }
    
    return node
}

/// Takes a series of nodes and flattens them from left-to-right by deep-merging their YAML trees
internal func createFlattenedNode(named name: String, nodes: [SpecNode], base: SpecNode?) -> SpecNode {
    let flattened = nodes.reduce(base ?? SpecNode(name: name)) {
        $0.merge(withNode: $1)
    }
    flattened.name = name // ensure the name is preserved during the LTR merge
    
    for child in flattened.children.values {
        child.metadata.annotations[AnnotationKey.typeGroup] = name // make all immediate children a member of this type group
    }
    
    return flattened
}
