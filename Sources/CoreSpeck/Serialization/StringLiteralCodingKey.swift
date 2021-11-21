//
//  StringLiteralCodingKey.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/13/21.
//

import Foundation

public struct StringLiteralCodingKey: CodingKey, ExpressibleByStringLiteral {
    public var stringValue: String
    
    public init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    public init(stringLiteral value: String) {
        self.stringValue = value
    }
    
    public var intValue: Int?
    
    public init(intValue: Int) {
        self.stringValue = intValue.description
    }
    
    public typealias StringLiteralType = String
}
