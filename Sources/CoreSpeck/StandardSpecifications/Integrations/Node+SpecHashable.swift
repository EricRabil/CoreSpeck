//
//  Node+SpecHashable.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/15/21.
//

import Foundation
import Yams

extension Node: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        switch self {
        case .scalar(let scalar): scalar.specHash(into: &hasher)
        case .mapping(let mapping): mapping.specHash(into: &hasher)
        case .sequence(let sequence): sequence.specHash(into: &hasher)
        }
    }
}

extension Node.Scalar: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        style.rawValue.description.specHash(into: &hasher)
        string.specHash(into: &hasher)
        tag.description.specHash(into: &hasher)
    }
}

extension Node.Sequence: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        forEach {
            $0.specHash(into: &hasher)
        }
        tag.description.specHash(into: &hasher)
    }
}

extension Node.Mapping: SpecHashable {
    public func specHash(into hasher: inout SpecHasher) {
        keys.sorted(by: >).forEach {
            $0.specHash(into: &hasher)
            self[$0]?.specHash(into: &hasher)
        }
        tag.description.specHash(into: &hasher)
    }
}
