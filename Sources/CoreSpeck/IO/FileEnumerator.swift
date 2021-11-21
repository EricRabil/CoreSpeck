//
//  FileEnumerator.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/13/21.
//

import Foundation

public extension FileManager {
    func enumerator(at url: URL) -> FileManager.DirectoryEnumerator {
        enumerator(at: url, includingPropertiesForKeys: nil)!
    }
}

public extension FileManager.DirectoryEnumerator {
    func enumerate(callback: (URL) throws -> ()) rethrows {
        while let element = autoreleasepool(invoking: { nextObject() as? URL }) {
            try callback(element)
        }
    }
}
