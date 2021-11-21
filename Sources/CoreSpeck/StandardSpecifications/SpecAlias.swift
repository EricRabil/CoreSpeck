//
//  SpecAlias.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/13/21.
//

import Foundation

public class SpecAlias {
    public var name: String
    
    public var aliasedName: String
    public var aliasedKind: SpecKind
    
    public var aliasedType: SpecType? {
        SpecificationRegistry.shared.specs[.tag(kind: aliasedKind, id: aliasedName)]
    }
    
    public var metadata: SpecMetadata
    
    public init(name: String, aliasedName: String, aliasedKind: SpecKind, metadata: SpecMetadata?) {
        self.name = name
        self.aliasedName = aliasedName
        self.metadata = metadata ?? SpecMetadata()
        self.aliasedKind = aliasedKind
    }
    
    public init(name: String, aliasedName: String, aliasedKind: SpecKind) {
        self.name = name
        self.aliasedName = aliasedName
        self.metadata = SpecMetadata()
        self.aliasedKind = aliasedKind
    }
}

extension SpecAlias: SpecType, SpecIdentifiable {
    public static var validKinds: [SpecKind] {
        [.reference]
    }
    
    public var isPrimitive: Bool { aliasedType?.isPrimitive ?? false }
    public var isCluster: Bool { aliasedType?.isCluster ?? false }
    public var isNode: Bool { aliasedType?.isNode ?? false }
    public var isCustomShape: Bool { aliasedType?.isCustomShape ?? false }
    
    public var kind: SpecKind {
        .reference
    }
}
