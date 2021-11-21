//
//  SpecHashable.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/14/21.
//

import Foundation
import CryptoKit

/*
 SpecHasher Manifesto
 
 The SpecHasher is a simple, stable MD5 hasher backed by data chunks
 */

public struct SpecHasher {
    fileprivate var guts: Data = Data()
    
    public func finalize() -> String {
        let digest = Insecure.MD5.hash(data: guts)
        
        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
    }
}

public protocol SpecHashable {
    func specHash(into hasher: inout SpecHasher)
}

public extension SpecHashable {
    var specHashValue: String {
        var hasher = SpecHasher()
        specHash(into: &hasher)
        return hasher.finalize()
    }
}

extension String: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        hasher.guts += Data(utf8)
    }
}

extension Data: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        hasher.guts += self
    }
}

extension Array: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) where Element == UInt8 {
        hasher.guts += Data(self)
    }
    
    public func specHash(into hasher: inout SpecHasher) where Element: SpecHashable {
        for element in self {
            element.specHash(into: &hasher)
        }
    }
    
    public func specHash(into hasher: inout SpecHasher) {
        preconditionFailure("You can't spec hash that, dummy.")
    }
}

extension RawRepresentable where RawValue: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        rawValue.specHash(into: &hasher)
    }
}

extension Bool: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        [self ? 1 : 0].specHash(into: &hasher)
    }
}
