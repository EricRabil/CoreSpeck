//
//  SpecEquatable.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/14/21.
//

import Foundation

// Why am I reinventing the wheel? Because Swift doesn't let you have equatable without PATs.
// Why don't they let you have equatable without PATs? Fuck you.
public protocol SpecEquatable {
    func isEqual(toType type: SpecType) -> Bool
}
