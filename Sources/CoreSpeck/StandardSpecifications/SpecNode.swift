//
//  SpecNode.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/13/21.
//

import Foundation

public class SpecNode {
    public var name: String
    public var children: [String: SpecType]
    public var metadata: SpecMetadata
    
    public init(name: String, children: [String: SpecType], metadata: SpecMetadata?) {
        self.name = name
        self.children = children
        self.metadata = metadata ?? SpecMetadata()
    }
    
    public init(name: String, children: [String: SpecType]) {
        self.name = name
        self.children = children
        self.metadata = SpecMetadata()
    }
    
    public init(name: String) {
        self.name = name
        self.children = [:]
        self.metadata = SpecMetadata()
    }
}

extension SpecNode: SpecType, SpecIdentifiable {
    public static var validKinds: [SpecKind] {
        [.object]
    }
    
    public var isPrimitive: Bool { false }
    public var isCluster: Bool { false }
    public var isNode: Bool { true }
    public var isCustomShape: Bool { false }
    
    public var kind: SpecKind {
        .object
    }
}
