//
//  SpecCustomization.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/14/21.
//

import Foundation
import Yams

public extension SpecKind {
    static let customization: SpecKind = "Customization"
}

internal extension Array {
    func withoutLast() -> ArraySlice<Element> {
        if count < 2 {
            return [][...]
        } else {
            return self[0..<(count - 1)]
        }
    }
}

public struct SpecCustomization: Codable, Equatable {
    public typealias Target = CustomizationTarget
    public typealias Patch = CustomizationPatch
    
    public var target: Target
    public var patches: [Patch]
    public var name: String
    
    public enum CustomizationError: Error {
        case pathResolutionFailure(path: String, reason: String)
    }
    
    public func apply(to node: SpecNode) throws -> SpecNode {
        var node = try Yams.compose(yaml: YAMLEncoder().encode(node))!
        
        for patch in patches {
            let intent = patch.value?.type ?? .scalar
            
            do {
                switch patch.operation {
                case .add:
                    fallthrough
                case .replace:
                    try node.locate(path: patch.path, accessIntent: intent) { mutatingNode in
                        mutatingNode = patch.value!
                    }
                case .append:
                    try node.locate(path: patch.path, accessIntent: .sequence) { mutatingNode in
                        mutatingNode.sequence!.append(patch.value!)
                    }
                case .remove:
                    let components = patch.path.split(separator: "/")
                    
                    if components.count > 1 {
                        try node.locate(path: components.withoutLast().joined(separator: "/"), accessIntent: intent) { mutatingNode in
                            mutatingNode[String(components.last!).replacingOccurrences(of: "~1", with: "/")] = nil
                        }
                    } else {
                        node[patch.path] = nil
                    }
                }
            } catch {
                guard let error = error as? Node.NodeAccessError else {
                    throw error
                }
                
                if case .subscriptingFailure = error, patch.missingBehavior == .skip {
                    continue
                } else {
                    throw error
                }
            }
        }
        
        return (try YAMLDecoder().decode(SpecType.self, from: Yams.serialize(node: node))) as! SpecNode
    }
}

extension SpecCustomization: SpecType, SpecIdentifiable {
    public static var validKinds: [SpecKind] {
        [.customization]
    }
    
    public var isPrimitive: Bool {
        false
    }
    
    public var isNode: Bool {
        false
    }
    
    public var isCustomShape: Bool {
        true
    }
    
    public var isCluster: Bool {
        false
    }
    
    public var metadata: SpecMetadata {
        SpecMetadata()
    }
    
    public var kind: SpecKind {
        .customization
    }
}
