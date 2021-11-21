//
//  CustomizationTarget.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/15/21.
//

import Foundation
import Yams

public struct CustomizationTarget: Equatable {
    public var kind: String?
    public var name: String?
    public var metadata: SpecMetadata?
    public var hashes: [String]? // a target can specify multiple hashes to apply patch to multiple models
    public var children: [Node.Mapping]?
    
    @inlinable public var isEmpty: Bool {
        if !isEmptyWithoutHashes {
            return false
        }
        
        if let hashes = hashes, !hashes.isEmpty {
            return false
        }
        
        return true
    }
    
    @inlinable public var isEmptyWithoutHashes: Bool {
        if kind != nil {
            return false
        }
        
        if name != nil {
            return false
        }
        
        if let metadata = metadata {
            if metadata.hash != nil {
                return false
            }
            
            if !metadata.annotations.isEmpty {
                return false
            }
        }
        
        if let children = children, children.count > 0 {
            return false
        }
        
        return true
    }
}
