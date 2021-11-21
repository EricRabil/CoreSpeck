import Foundation
import CoreSpeck
import Yams

let sources = URL(fileURLWithPath: "/Users/ericrabil/Documents/iMessagePayloads")
let outputDirectory = URL(fileURLWithPath: "/Users/ericrabil/Documents/iMessageSpeck")
let customizationDirectory = URL(fileURLWithPath: "/Users/ericrabil/Documents/iMessageCustomizations")
let generatedDirectory = URL(fileURLWithPath: "/Users/ericrabil/Documents/iMessageGenerations")

let nodes: [SpecNode] = try XMLImporter.massImport(fromSource: sources)

extension URL {
    func empty() throws {
        try FileManager.default.enumerator(at: self).enumerate { url in
            try FileManager.default.removeItem(at: url)
        }
    }
}

try outputDirectory.empty()

for node in nodes {
    let data = try YAMLEncoder().encode(node)
    try data.write(to: outputDirectory.appendingPathComponent(node.name.appending(".yml")), atomically: false, encoding: .utf8)
}

try SpecificationRegistry.shared.loadRecursively(fromURL: outputDirectory)
try SpecificationRegistry.shared.loadRecursively(fromURL: customizationDirectory)

let customizedNodes = try CustomizationEngine.shared.applyCustomizations(toNodes: nodes)

let generator = SwiftGenerator()

generator.eat(nodes: customizedNodes)

try generatedDirectory.empty()

for (name, type) in generator.types {
    let data = try YAMLEncoder().encode(type)
    try data.write(to: generatedDirectory.appendingPathComponent(name.appending(".yml")), atomically: false, encoding: .utf8)
}

for rendered in generator.renderEverything() {
    print(rendered)
}
