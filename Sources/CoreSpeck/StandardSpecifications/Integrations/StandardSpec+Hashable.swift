//
//  StandardSpec+Hashable.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/14/21.
//

import Foundation
import Yams

// Truly, you do not want to ever fuck with the hashing algorithm. It is expected to be a constant measure of the intrinsic structure.
// This is a promise. You can use hash values as selectors for overlaying onto imported types.

public extension Hasher {
    static func randomSeed() -> [UInt8] {
        Array(unsafeUninitializedCapacity: 32) { pointer, initializedCount in
            for i in 0..<32 {
                pointer[i] = UInt8(arc4random())
            }
            
            initializedCount = 32
        }
    }
    
    static let speckHash: [UInt8] = [235, 45, 216, 214, 16, 112, 184, 247, 156, 181, 159, 38, 245, 165, 35, 224, 255, 58, 206, 200, 16, 122, 174, 232, 130, 191, 143, 49, 246, 179, 41, 240]
    
    static func speckHasher() -> Hasher {
        Hasher(seed: speckHash)
    }
    
    init(seed: [UInt8]) {
        guard seed.count == 32 else {
            preconditionFailure("Seed must be exactly 32 bytes")
        }
        
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: MemoryLayout<Hasher>.size, alignment: MemoryLayout<Hasher>.alignment)
        
        for index in 0..<8 {
            buffer[index] = 0
        }
        
        for index in 8..<40 {
            buffer[index] = seed[index - 8]
        }
        
        for index in 40..<72 {
            buffer[index] = 0
        }
        
        self = buffer.bindMemory(to: Hasher.self).baseAddress!.pointee
    }
}

extension SpecPrimitive: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        kind.specHash(into: &hasher)
        primitiveKind.rawValue.specHash(into: &hasher)
    }
}

extension SpecCluster: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        kind.specHash(into: &hasher)
        element.specHash(into: &hasher)
        key?.specHash(into: &hasher)
    }
}

extension SpecNode: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        kind.specHash(into: &hasher)
        
        for key in children.keys.sorted(by: >) {
            key.specHash(into: &hasher)
            children[key]!.specHash(into: &hasher)
        }
    }
}

extension SpecAlias: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        kind.specHash(into: &hasher)
        aliasedName.specHash(into: &hasher)
        aliasedKind.specHash(into: &hasher)
    }
}

extension CustomizationTarget: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        kind?.specHash(into: &hasher)
        name?.specHash(into: &hasher)
        hashes?.specHash(into: &hasher)
        children?.specHash(into: &hasher)
        metadata?.hash?.specHash(into: &hasher)
        metadata?.annotations.specHash(into: &hasher)
    }
}

extension Dictionary: SpecHashable where Key == String, Value == String {
    public func specHash(into hasher: inout SpecHasher) {
        for key in keys.sorted(by: >) {
            key.specHash(into: &hasher)
            self[key]?.specHash(into: &hasher)
        }
    }
}

extension CustomizationPatch: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        operation.specHash(into: &hasher)
        path.specHash(into: &hasher)
        
        if let value = value {
            do {
                let string = try Yams.serialize(node: value)
                string.specHash(into: &hasher)
            } catch {}
        }
    }
}

extension SpecCustomization: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        kind.specHash(into: &hasher)
        target.specHash(into: &hasher)
        
        for patch in patches {
            patch.specHash(into: &hasher)
        }
    }
}

extension SpecEnumeration: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        kind.specHash(into: &hasher)
        enumerationKind.specHash(into: &hasher)
        extensible.specHash(into: &hasher)
        cases.specHash(into: &hasher)
    }
}
