//
//  CustomizationPatchj.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/15/21.
//

import Foundation
import Yams

public struct CustomizationPatch: Equatable {
    public enum PatchType: String, Codable, Hashable, Equatable {
        case add, replace, remove, append
    }
    
    public enum MissingBehavior: String, Codable, Hashable, Equatable {
        case skip, `throw`
    }
    
    public var operation: PatchType
    public var path: String
    public var missingBehavior: MissingBehavior
    
    public var metadata: SpecMetadata
    public var value: Node?
}
