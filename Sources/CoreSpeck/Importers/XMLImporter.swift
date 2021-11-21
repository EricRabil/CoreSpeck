//
//  XMLImporter.swift
//  CoreSpeck
//
//  Created by Eric Rabil on 11/13/21.
//

import Foundation

public class XMLImporter: Importer {
    public enum XMLImportError: Error {
        case parserInitializationFailed
        case unknownParsingFailure
    }
    
    public static func canImport(url: URL) -> Bool {
        url.pathExtension == "xml" || url.pathExtension == "plist"
    }
    required public init() {}
    
    public func `import`(url: URL) throws -> SpecNode {
        try XMLSpecGenerator(name: url.lastPathComponent, metadata: nil).parse(contentsOf: url)
    }
}

private class XMLSpecGenerator: NSObject, XMLParserDelegate {
    let rootNode: SpecNode
    var builder: SpecBuilder
    var rootMetadata: SpecMetadata = SpecMetadata()
    
    private var internalParserError: Error?
    
    init(name: String, metadata: SpecMetadata?) {
        let builder = SpecNodeBuilder(name: name, metadata: rootMetadata)
        rootNode = builder.node
        self.builder = builder
    }
    
    func parse(contentsOf url: URL) throws -> SpecNode {
        guard let parser = XMLParser(contentsOf: url) else {
            throw XMLImporter.XMLImportError.parserInitializationFailed
        }
        
        parser.delegate = self
        
        var annotations: [String: String] = [:]
        annotations["ericrabil.com/xml-import-source"] = url.absoluteString
        rootMetadata.annotations = annotations
        
        guard parser.parse() else {
            throw internalParserError ?? parser.parserError ?? XMLImporter.XMLImportError.unknownParsingFailure
        }
        
        return rootNode
    }
    
    var nextTextIsName: Bool = false
    var name: String? = nil
    
    func enterDictionary(withKey key: String?) throws {
        builder = try builder.pushDictionary(withKey: key)
    }
    
    func enterArray(withKey key: String?) throws {
        builder = try builder.pushArray(withKey: key)
    }
    
    func moveOut() throws {
        builder = try builder.moveOut()
    }
    
    func store(primitive: SpecPrimitive, withKey key: String?) throws {
        builder = try builder.pushPrimitive(withType: primitive, key: key)
    }
    
    func store(primitive: SpecPrimitive.Kind, withKey key: String?) throws {
        builder = try builder.pushPrimitive(withType: .init(kind: primitive), key: key)
    }
    
    var phase = 0
    
    var nextKey: String?
    var onText: ((String) -> ())?
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        do {
            switch phase {
            case 0:
                phase = elementName == "plist" ? 1 : 0
                return
            case 1:
                phase = elementName == "dict" ? 2 : 1
                return
            default:
                break
            }
            
            let key = nextKey
            nextKey = nil
            
            switch elementName {
            case "key":
                onText = {
                    self.nextKey = $0
                    self.onText = nil
                }
            case "string":
                try store(primitive: .string, withKey: key)
            case "integer":
                try store(primitive: .integer, withKey: key)
            case "real":
                try store(primitive: .double, withKey: key)
            case "true":
                fallthrough
            case "false":
                try store(primitive: .bool, withKey: key)
            case "date":
                try store(primitive: .date, withKey: key)
            case "data":
                try store(primitive: .data, withKey: key)
            case "dict":
                try enterDictionary(withKey: key)
            case "array":
                try enterArray(withKey: key)
            default:
                print("Unknown elementName: \(elementName)")
            }
        } catch {
            internalParserError = error
            parser.abortParsing()
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        do {
            switch elementName {
            case "key":
                break
            default:
                try moveOut()
            }
        } catch {
            internalParserError = error
            parser.abortParsing()
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        onText?(string)
    }
}

public extension XMLImporter {
    static func massImport(fromSource source: URL) throws -> [SpecNode] {
        var nodes: [SpecNode] = []
        
        try FileManager.default.enumerator(at: source).enumerate { url in
            let parsedNode = try XMLImporter().import(url: url)
            
            if nodes.contains(where: {
                $0.specHashValue == parsedNode.specHashValue
            }) {
                return
            }
            
            parsedNode.metadata.hash = parsedNode.specHashValue
            nodes.append(parsedNode)
        }
        
        return nodes
    }
}
