//
//  _TypeGroupProcessor.swift
//  CoreSpeck
//
//  Supports the aggregation of type groups as types are processed
//
//  Created by Eric Rabil on 11/20/21.
//

import Foundation

internal extension AnnotationKey {
    static let typeGroup: AnnotationKey = "ericrabil.com/type-group"
}

// Annotation processors are called recursively, this will bag and tag any node children that identify with a type group
internal class _TypeGroupProcessor: AnnotationProcessor, AnnotationProcessorKindDiscriminating {
    let supportedKinds: [SpecKind] = [.object]
    let supportedAnnotations: [AnnotationKey] = []
    var delegate: AnnotationProcessorDelegate?
    
    private var _delegate: _PrivateAnnotationProcessorDelegate? {
        delegate as? _PrivateAnnotationProcessorDelegate
    }
    
    func process(spec: SpecType) -> SpecType? {
        if let node = spec as? SpecNode {
            for (childName, child) in node.children {
                if let typeGroup = child.metadata.annotations[AnnotationKey.typeGroup] {
                    _delegate?.processor(self, foundSpec: node.children[childName] ?? child, named: childName, inTypeGroup: typeGroup)
                }
            }
        }
        
        return spec
    }
}
