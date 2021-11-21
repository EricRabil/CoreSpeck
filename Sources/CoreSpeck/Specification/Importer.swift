//
//  Importer.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/13/21.
//

import Foundation

public protocol Importer {
    static func canImport(url: URL) -> Bool
    init()
    func `import`(url: URL) throws -> SpecNode
}
