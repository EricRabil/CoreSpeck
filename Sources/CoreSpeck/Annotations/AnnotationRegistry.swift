//
//  AnnotationRegistry.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/20/21.
//

import Foundation

public protocol AnnotationProcessorDelegate {
    /// Ingest a spec as a root type
    func processor<SpecType: SpecIdentifiable>(_ processor: AnnotationProcessor, createdSpec spec: SpecType)
}

protocol _PrivateAnnotationProcessorDelegate: AnnotationProcessorDelegate {
    /// (INTERNAL) Ingest a spec capture as a type group aggregate member.
    func processor(_ processor: AnnotationProcessor, foundSpec spec: @escaping @autoclosure () -> SpecType, named name: String, inTypeGroup typeGroup: String)
}

public protocol AnnotationProcessor: AnyObject {
    // This array is not mutually exclusive - if any annotation matches, the spec will be processed.
    var supportedAnnotations: [AnnotationKey] { get }
    var delegate: AnnotationProcessorDelegate? { get set }
    
    /// It is expected that this processor will return a cloned spec if changes are made, otherwise you can return the argument
    func process(spec: SpecType) -> SpecType?
}

public protocol AnnotationProcessorKindDiscriminating: AnnotationProcessor {
    var supportedKinds: [SpecKind] { get }
}

/// Manages implementation drivers for annotations
public class AnnotationRegistry {
    public enum RegistrationErorr: Error {
        case annotationKeyCollission
    }
    
    public static let shared = AnnotationRegistry()
    
    private var kindOnlyProcessors: [SpecKind: [AnnotationProcessor]] = [:]
    private var processors: [AnnotationKey: AnnotationProcessor] = [:]
    
    private init() {
        register(processor: TypeLiftingProcessor()) {}
        register(processor: EnumSynthesisProcessor()) {}
        register(processor: _TypeGroupProcessor()) {}
    }
    
    private func register(processor: AnnotationProcessor, onCollission: () throws -> ()) rethrows {
        if processor.supportedAnnotations.isEmpty, let processor = processor as? AnnotationProcessorKindDiscriminating {
            for kind in processor.supportedKinds {
                kindOnlyProcessors[kind, default: []].append(processor)
            }
        } else {
            for key in processor.supportedAnnotations {
                if processors.keys.contains(key) {
                    try onCollission()
                }
                
                processors[key] = processor
            }
        }
    }
    
    /// Register a new annotation processor to be used during mashing. Throws if another processor already claims an annotation.
    public func register(processor: AnnotationProcessor) throws {
        try register(processor: processor) {
            throw RegistrationErorr.annotationKeyCollission
        }
    }
    
    public var delegate: AnnotationProcessorDelegate? {
        didSet {
            for processor in processors.values {
                processor.delegate = delegate
            }
            
            for processors in kindOnlyProcessors.values {
                for processor in processors {
                    processor.delegate = delegate
                }
            }
        }
    }
}

public extension AnnotationRegistry {
    /// Returns all processors capable of processing the spec
    private func processors(forSpec spec: SpecType) -> [AnnotationProcessor] {
        (kindOnlyProcessors[spec.kind] ?? []) + spec.metadata.annotations.keys.map(AnnotationKey.init(stringLiteral:)).compactMap {
            processors[$0]
        }.filter { processor in
            switch processor {
            case let processor as AnnotationProcessorKindDiscriminating:
                return processor.supportedKinds.contains(spec.kind)
            default:
                return true
            }
        }
    }
    
    /// Recursively descends through a spec, feeding each level to their designated annotation parsers
    func process(spec: SpecType) -> SpecType? {
        var topLevel = spec
        
        for processor in processors(forSpec: topLevel) {
            guard let newSpec = processor.process(spec: spec) else {
                return nil
            }
            
            topLevel = newSpec
        }
        
        switch topLevel {
        case let spec as SpecNode:
            spec.children = spec.children.compactMapValues { spec in
                process(spec: spec)
            }
            return spec
        case var cluster as SpecCluster:
            cluster.key = cluster.key.flatMap(process(spec:))
            guard let newElement = process(spec: cluster.element) else {
                return nil
            }
            cluster.element = newElement
            return cluster
        default:
            return topLevel
        }
    }
}
