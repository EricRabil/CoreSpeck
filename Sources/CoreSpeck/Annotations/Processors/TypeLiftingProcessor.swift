//
//  TypeLiftingProcessor.swift
//  CoreSpeck
//
//  Supports the extraction of nested types to a root type + alias replacement
//
//  Created by Eric Rabil on 11/20/21.
//

import Foundation

private extension AnnotationKey {
    static let liftedType: AnnotationKey = "ericrabil.com/extracted-type-name"
}

public class TypeLiftingProcessor: AnnotationProcessor, AnnotationProcessorKindDiscriminating {
    public let supportedKinds: [SpecKind] = [.object]
    public let supportedAnnotations: [AnnotationKey] = [.liftedType]
    
    public var delegate: AnnotationProcessorDelegate?
    
    public func process(spec: SpecType) -> SpecType? {
        guard let liftedTypeName = spec.metadata.annotations[AnnotationKey.liftedType], let spec = spec as? SpecNode else {
            return spec
        }
        
        let liftedTypeAlias = spec.makeAlias(withName: liftedTypeName)
        liftedTypeAlias.stripAnnotations(withKeys: [.liftedType])
        
        let liftedType = spec.clone()
        liftedType.name = liftedTypeName
        liftedType.stripAnnotations(withKeys: [.liftedType])
        
        delegate?.processor(self, createdSpec: liftedType)
        
        return liftedTypeAlias
    }
}
