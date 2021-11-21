//
//  Node+PathResolver.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/15/21.
//

import Foundation
import Yams

extension Node {
    var isMapping: Bool {
        mapping != nil
    }
    
    var isSequence: Bool {
        sequence != nil
    }
    
    /*
     location algorithm:
     
     take path string, like such:
     /asdf/0/fdsa/pp.com~1vnfdja
     
     translate it to:
     [asdf, 0, fdsa, pp.com/vnfdja]
     
     walk self
     if missing node along the way, try to reconcile
     
     if self is sequence and component is number, insert component and continue
     if self is mapping and component is any, insert component and continue
     if self is scalar and component is not nil, error
     if no solution, error
     
     if self is any and component is nil, callback yield self
     */
    
    enum NodeType {
        case scalar, sequence, mapping
    }
    
    enum NodeAccessError: Error {
        case scalarAccessError(path: String, message: String)
        case sequenceAccessError(path: String, message: String)
        case subscriptingFailure(path: String, message: String)
    }
    
    var type: NodeType {
        if scalar != nil {
            return .scalar
        } else if sequence != nil {
            return .sequence
        } else {
            return .mapping
        }
    }
    
    private mutating func locate(originalPath: String, components: ArraySlice<String>, accessIntent: NodeType, callback: (inout Node) throws -> ()) throws {
        if components.count == 0 {
            return try callback(&self)
        }
        
        var chopped: ArraySlice<String> {
            if components.count < 2 {
                return [][...]
            } else {
                return components[components.index(after: components.startIndex)...]
            }
        }
        
        let firstComponent = components.first!
        let nextComponent = components.count > 1 ? components[components.index(after: components.startIndex)] : nil
        let type = type
        
        switch type {
        case .scalar:
            throw NodeAccessError.scalarAccessError(path: originalPath, message: "Attempt to subscript a scalar which is forbidden")
        case .sequence:
            guard let index = Int(firstComponent) else {
                throw NodeAccessError.sequenceAccessError(path: originalPath, message: "Attempt to subscript a sequence with a string which is forbidden")
            }
            
            if self[index] == nil {
                if nextComponent == nil {
                    switch accessIntent {
                    case .scalar:
                        self[index] = Node.scalar(.init(""))
                    case .sequence:
                        self[index] = Node([Node]())
                    case .mapping:
                        self[index] = Node([(Node, Node)]())
                    }
                    
                    // yield inserted
                    return try callback(&self[index]!)
                } else {
                    throw NodeAccessError.subscriptingFailure(path: originalPath, message: "Attempt to subscript with multiple levels of undefined-ness, which is forbidden")
                }
            }
            
            return try self[index]!.locate(originalPath: originalPath, components: chopped, accessIntent: accessIntent, callback: callback)
        case .mapping:
            if self[firstComponent] == nil {
                if nextComponent == nil {
                    switch accessIntent {
                    case .scalar:
                        self[firstComponent] = Node.scalar(.init(""))
                    case .sequence:
                        self[firstComponent] = Node([Node]())
                    case .mapping:
                        self[firstComponent] = Node([(Node, Node)]())
                    }
                    
                    // yield inserted
                    return try callback(&self[firstComponent]!)
                } else {
                    throw NodeAccessError.subscriptingFailure(path: originalPath, message: "Attempt to subscript with multiple levels of undefined-ness, which is forbidden")
                }
            }
            
            return try self[firstComponent]!.locate(originalPath: originalPath, components: chopped, accessIntent: accessIntent, callback: callback)
        }
    }
    
    mutating func locate(path: String, accessIntent: NodeType, callback: (inout Node) throws -> ()) throws {
        try locate(originalPath: path, components: path.split(separator: "/").map {
            $0.replacingOccurrences(of: "~1", with: "/")
        }[...], accessIntent: accessIntent, callback: callback)
    }
}
