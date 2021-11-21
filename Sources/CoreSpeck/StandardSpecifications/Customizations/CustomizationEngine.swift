//
//  CustomizationEngine.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/14/21.
//

import Foundation
import Yams

public extension SpecNode {
    func clone() -> SpecNode {
        try! YAMLDecoder().decode(SpecType.self, from: YAMLEncoder().encode(self)) as! SpecNode
    }
}

private extension SpecificationRegistry {
    var allNodes: [SpecTag: SpecNode] {
        specs.compactMapValues {
            $0 as? SpecNode
        }
    }
}

private extension Dictionary {
    func filterValues(_ inspector: (Value) throws -> Bool) rethrows -> Dictionary {
        try compactMapValues {
            try inspector($0) ? $0 : nil
        }
    }
}

private extension SpecNode {
    func matches(target: CustomizationTarget) -> Bool {
        if target.isEmpty {
            return false
        }
        
        if let hashes = target.hashes {
            if hashes.contains(specHashValue) {
                return true // unconditionally included if specified here
            }
        }
        
        if target.isEmptyWithoutHashes {
            return false
        }
        
        if let childrenAggregate = target.children, !childrenAggregate.isEmpty {
            do {
                let hasMatch = try childrenAggregate.contains { children in
                    let childrenFragment = try SpecificationRegistry.shared.decodeSpecs(fromYaml: Yams.serialize(node: .mapping(children)))
                    
                    for (name, node) in childrenFragment {
                        guard let ownChild = self.children[name] else {
                            return false
                        }
                        
                        guard node.isEqual(toType: ownChild) else {
                            return false
                        }
                    }
                    
                    return true
                }
                
                if !hasMatch {
                    return false
                }
            } catch {
                
            }
        }
        
        if let name = target.name {
            guard self.name == name else {
                return false
            }
        }
        
        if let kind = target.kind {
            guard self.kind.rawValue == kind else {
                return false
            }
        }
        
        if let metadata = target.metadata {
            if let hash = metadata.hash {
                guard self.metadata.hash == hash else {
                    return false
                }
            }
            
            for (annotationKey, annotationValue) in metadata.annotations {
                guard self.metadata.annotations[annotationKey] == annotationValue else {
                    return false
                }
            }
        }
        
        return true
    }
}

public class CustomizationEngine {
    public static let shared = CustomizationEngine()
    
    public private(set) var customizations: [SpecTag: SpecCustomization] = [:]
    
    fileprivate func loadCustomizations(atURL url: URL) {
        FileManager.default.enumerator(at: url).enumerate { url in
            guard url.pathExtension == "yml" || url.pathExtension == "yaml" else {
                return
            }
            
            do {
                guard let spec = try SpecificationRegistry.shared.decodeSpec(fromYaml: Data(contentsOf: url)) as? SpecCustomization else {
                    return
                }
                
                customizations[.tag(kind: .customization, id: spec.name)] = spec
            } catch (let error) {
                print(error)
            }
        }
    }
    
    fileprivate var customizingNodes: [ObjectIdentifier: SpecNode] = [:]
    
    fileprivate func matches(forCustomization customization: SpecCustomization) -> [ObjectIdentifier: SpecNode] {
        customizingNodes.filterValues { node in
            node.matches(target: customization.target)
        }
    }
    
    fileprivate func apply(customization: SpecCustomization) throws {
        for match in matches(forCustomization: customization) {
            customizingNodes[match.key] = try customization.apply(to: match.value)
        }
    }
    
    public func applyCustomizations(toNodes nodes: [SpecNode]) throws -> [SpecNode] {
        customizingNodes = Dictionary(uniqueKeysWithValues: nodes.map { $0.clone() }.map { (ObjectIdentifier($0), $0) })
        customizations = SpecificationRegistry.shared.specs.compactMapValues {
            $0 as? SpecCustomization
        }
        
        try customizations.values.forEach(apply(customization:))
        
        return Array(customizingNodes.values)
    }
}
