//
//  EnumSynthesisProcessor.swift
//  CoreSpeck
//
//  Supports the transpilation of open/closed enum annotations to an enum type reference
//
//  Created by Eric Rabil on 11/19/21.
//

import Foundation
import Yams

private extension AnnotationKey {
    static let openEnumeration: AnnotationKey = "ericrabil.com/open-enumeration"
    static let closedEnumeration: AnnotationKey = "ericrabil.com/closed-enumeration"
}

private extension Dictionary {
    subscript<Representable: RawRepresentable>(either either: Representable, or or: Representable) -> Value? where Representable.RawValue == Key {
        if keys.contains(either) && keys.contains(or) {
            return nil
        }
        
        return self[either] ?? self[or]
    }
}

public class EnumSynthesisProcessor: AnnotationProcessor, AnnotationProcessorKindDiscriminating {
    private struct EnumDeclaration: Codable {
        var kind: SpecPrimitive.Kind
        var metadata: SpecMetadata?
        var name: String
        var cases: [String: String]
    }
    
    public let supportedKinds: [SpecKind] = [.primitive]
    public let supportedAnnotations: [AnnotationKey] = [
        .openEnumeration, .closedEnumeration
    ]
    
    public var delegate: AnnotationProcessorDelegate?
    
    public func process(spec: SpecType) -> SpecType? {
        do {
            guard spec is SpecPrimitive, let rawDeclaration = spec.metadata.annotations[either: AnnotationKey.openEnumeration, or: AnnotationKey.closedEnumeration] else {
                return spec
            }
            
            let parsedDeclaration: EnumDeclaration = try YAMLDecoder().decode(from: rawDeclaration)
            
            let syntheticEnum = SpecEnumeration (
                name: parsedDeclaration.name,
                extensible: spec.metadata.annotations[AnnotationKey.openEnumeration] != nil,
                metadata: parsedDeclaration.metadata ?? SpecMetadata(),
                enumerationKind: parsedDeclaration.kind,
                cases: parsedDeclaration.cases
            )
            
            let alias = syntheticEnum.makeAlias(inheritingMetadata: spec)
            alias.stripAnnotations(withKeys: [
                .closedEnumeration, .openEnumeration
            ])
            
            delegate?.processor(self, createdSpec: syntheticEnum)
            
            return alias
        } catch {
            return spec
        }
    }
}
