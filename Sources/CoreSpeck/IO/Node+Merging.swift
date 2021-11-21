//
//  Node+Merging.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/16/21.
//

import Foundation
import Yams

extension Node.Mapping {
    public mutating func merge(mapping: Node.Mapping) {
        for (key, value) in mapping {
            if let subMapping = value.mapping {
                if self[key] == nil {
                    self[key] = .mapping(.init([]))
                }
                
                self[key]?.mapping?.merge(mapping: subMapping)
            } else {
                self[key] = value
            }
        }
    }
}

extension Node.Sequence {
    public mutating func merge(sequence: Node.Sequence) {
        for index in sequence.indices {
            if indices.contains(index) {
                self[index].merge(node: sequence[index])
            } else if index == count {
                append(sequence[index])
            } else {
                reserveCapacity(index + 1)
                
                for _ in count...index {
                    append(.scalar(.init("")))
                }
                
                self[index] = sequence[index]
            }
        }
    }
}

extension Node {
    public mutating func merge(node: Node) {
        switch node {
        case .mapping(let mapping):
            switch self {
            case .mapping:
                self.mapping!.merge(mapping: mapping)
            default:
                break
            }
        case .scalar:
            break
        case .sequence(let sequence):
            switch self {
            case .sequence:
                self.sequence!.merge(sequence: sequence)
            default:
                break
            }
        }
    }
    
    public func merging(with mapping: Node) -> Node {
        var clone = self
        clone.merge(node: mapping)
        return clone
    }
    
    public func parse<P: Decodable>() throws -> P {
        try YAMLDecoder().decode(from: serialize(node: self))
    }
    
    public func parse() throws -> SpecType {
        try YAMLDecoder().decode(SpecType.self, from: serialize(node: self))
    }
}

extension SpecType {
    private var yamlNode: Node {
        try! Yams.compose(yaml: YAMLEncoder().encode(self))!
    }
    
    public func merge(withNode node: Self) -> Self {
        (merge(withNode: node as SpecType) as SpecType) as! Self
    }
    
    public func merge(withNode node: SpecType) -> SpecType {
        try! yamlNode.merging(with: node.yamlNode).parse()
    }
}
