//
//  SpecKind.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/14/21.
//

import Foundation

public struct SpecKind: Codable, RawRepresentable, ExpressibleByStringLiteral, CustomStringConvertible, Equatable, Hashable {
    public var name: String
    
    public init(stringLiteral: String) {
        name = stringLiteral
    }
    
    public init(rawValue: String) {
        name = rawValue
    }
    
    public var rawValue: String {
        name
    }
    
    public var description: String {
        name
    }
}
