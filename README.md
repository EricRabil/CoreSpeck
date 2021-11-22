# CoreSpeck

CoreSpeck is the framework driving Speck, a language-agnostic type management system.

Speck has four components:

- [Importing](#Importing)
- [Customizations](#Customizations)
- [Type mashing & annotation processing](#Type Mashing)
- [Transpilation](#Transpilation)

## Importing

Speck provides APIs that make it easy to ingest arbitrary data, allowing you to build up your models from live data. This is especially useful for scenarios in which you do not have access to the original documentation, and wish to reconstruct an API model from responses. For your convenience, there is a reference implementation of an importer utilizing these APIs at [XMLImporter](Sources/CoreSpeck/Importers/XMLImporter.swift).

You are encouraged to import as many pieces of data as needed to get good coverage of the API you are documenting. This allows you to have representative types. There are annotations that exist which allow you to specify nullability, as well as make grouped nullability (via synthesized aggregates), in the event you have uneven responses.

An example of why you can never over-import is the iMessage protocol – it uses a nearly entirely flat structure, with groups of keys that are either always or never present, many keys that are optionally present, many keys that may be present or missing if a key is present, otherwise always missing, and keys that are simply always present. This creates a very complex serialized format, and by importing a large set of data you are able to perform complex customizations that restructure these payloads into comprehensible, nested types.

### SpecBuilder

The import system is powered by [SpecBuilder](Sources/CoreSpeck/Importers/Builder/SpecBuilder.swift), an interface that allows you to construct a tree of data as you process the corresponding raw data.

```swift
/// SpecBuilders are an abstraction for scaffolding out a specification while parsing arbitrary data. There is a reference implementation of an XML importer that demonstrates how this can be used.
public protocol SpecBuilder {
    var specType: SpecType { get }
    
    /// Descend into an array builder, optionally keyed depending on your current context
    func pushArray(withKey key: String?) throws -> SpecBuilder
    /// Descend into a dictionary builder, optionally keyed depending on your current context
    func pushDictionary(withKey key: String?) throws -> SpecBuilder
    /// Returns the parent, or self if this is the top
    func moveOut() throws -> SpecBuilder
    /// Descend into a primitive builder, which you should immediately move back out of.
    func pushPrimitive(withType type: SpecPrimitive, key: String?) throws -> SpecBuilder
}

public enum SpecBuilderError: Error {
    /// Thrown when a key is not passed but the builder is a dictionary builder
    case keyInconsistencyError
    /// Thrown when a key is passed but the builder is an array builder
    case arrayInconsistencyError
    /// Thrown when attempting to write to a primitive builder. You should move back out of it, it is a terminal point.
    case primitiveAbuseError
}
```

## Customizations

Customizations allow you to have granular control over how your types are documented, transpiled, and handled in later processing stages. Their main, but not only, purpose is to add annotations to properties in a type to adjust how they are mashed. For example,

```yml
kind: Object
name: 624B3339-B52C-4D10-9451-3893669A2FC3.plist
metadata:
  hash: bf8d7b4d9eeb9bcebe94a3d2ccdbdef5
  annotations:
    ericrabil.com/xml-import-source: file:///Users/ericrabil/Documents/iMessagePayloads/624B3339-B52C-4D10-9451-3893669A2FC3.plist
children:
  v:
    kind: Primitive
    type: String
  amrlc:
    kind: Primitive
    type: Integer
  amt:
    kind: Primitive
    type: Integer
  gid:
    kind: Primitive
    type: String
  msi:
    kind: Primitive
    type: Data
  amk:
    kind: Primitive
    type: String
  gv:
    kind: Primitive
    type: String
  p:
    kind: Array
    element:
      kind: Primitive
      type: String
  amrln:
    kind: Primitive
    type: Integer
  r:
    kind: Primitive
    type: String
  gpru:
    kind: Primitive
    type: Integer
  n:
    kind: Primitive
    type: String
  pv:
    kind: Primitive
    type: Integer
  t:
    kind: Primitive
    type: String
```

The above spec represents an iMessage payload in a group chat, in which someone has sent a message acknowledgment. Here's what we know about this payload:

`amrlc`, `amt`, `amk`, and `amrln` will either all be present, or all be absent. They are the bits that represent the message acknowledgment. Through this, we can write the following customization which will instruct the type masher to lift those four properties out to their own structure:

```yaml
kind: Customization
name: IMAssociatedMessageWireAnnotations
target:
  children: |
    amk:
      kind: Primitive
      type: String
patches:
  - op: add
    path: /children/amk/metadata
    value:
      annotations:
        ericrabil.com/type-group: IMMessageAssociation
        ericrabil.com/readable-name: associatedMessageGUID
      description: The GUID of the message this message is associated with.
  - op: add
    path: /children/amt/metadata
    value:
      annotations:
        ericrabil.com/type-group: IMMessageAssociation
        ericrabil.com/readable-name: associatedMessageType
      description: The type of associated message being sent.
  - op: add
    path: /children/amrlc/metadata
    value:
      annotations:
        ericrabil.com/type-group: IMMessageAssociation
        ericrabil.com/readable-name: associatedMessageLowerBound
      description: In a rich message, the first character (as in an attributed string) that is part of the association.
  - op: add
    path: /children/amrln/metadata
    value:
      annotations:
        ericrabil.com/type-group: IMMessageAssociation
        ericrabil.com/readable-name: associatedMessageUpperBound
      description: In a rich message, the last character (as in an attributed string) that is part of the association.
  - op: add
    path: /children/messageAssociation
    value:
      kind: Reference
      name: messageAssociation
      aliasedName: IMMessageAssociation
      aliasedKind: Object
      metadata:
        annotations:
          ericrabil.com/type-group: IMMessage
          ericrabil.com/synthesized-aggregate: IMMessageAssociation
          ericrabil.com/value-nullable: true
        description: If present, identifies the message this message should be correlated to.
```

In this customization, we are targeting all payloads which contain `amk`, in which case we assert that `amt`, `amrlc`, and `amrln` will also be present. Each of these properties receive the following annotations:

- `ericrabil.com/type-group`: This instructs the type masher to store the associated property within a type named `IMMessageAssociation`. If we wanted it to be in the root message, we could've put `IMMessage` instead, but for clarity we will lift them out to their own association object.
- `ericrabil.com/readable-name`: This instructs code generators to use the associated text (i.e. `associatedMessageGUID` rather than `amk`) when defining the type, but to still use `amk` for de/serialization.

At the bottom of the customization, we add a new child to the acknowldegment message called `messageAssociation`. This object is known as a "synthesized aggregate", which means "a type that is a logical collection of values from a pre-existing type". However, because this collection of values is actually from another type, synthesized aggregates are de/serialized inline with their parent, rather than being nested. This allows you to maintain serialization compatibility, while creating order from chaos.

Here's an example of Swift-generated code with and without a synthesized aggregate

```swift
struct IMMessage: IMBaseMessage { 
    /// The unique identifier of this conversation.
    var groupID: String
    /// The name of this group chat, if set. If it missing, the group is no longer named.
    var groupName: String?
    /// The incrementing number correlated to the chat properties revision history.
    var propertiesVersion: Int
    /// The group protocol version, which should always be 8.
    var groupVersion: String
    /// When present, this message is in reply to another message.
    var threadIdentifier: String?
    /// The participants this message has been sent to.
    var participants: [String]
    /// The GUID of the message this message is associated with.
    var associatedMessageGUID: String?
    /// Human-readable message text, can be used as a fallback text or the default if no other message formats are provided.
    var textContent: String
    /// The type of associated message being sent.
    var associatedMessageType: IMMessageAssociationType?
    /// In a rich message, the first character (as in an attributed string) that is part of the association.
    var associatedMessageLowerBound: Int?
    /// If present, provides the plugin payload.
    var pluginMessage: IMPluginMessage?
    /// The base protocol version, which should always be 1.
    var protocolVersion: String
    /// In a rich message, the last character (as in an attributed string) that is part of the association.
    var associatedMessageUpperBound: Int?
    /// The GUID of the message prior to this one
    var replyToGUID: String
    /// HTML-based rich text for this message
    var richContent: String?
    /// A binary property list with additional information about this message.
    var messageSummaryInfo: Data?
}

extension IMMessage: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMBaseMessage
        groupID = try container.decode(String.self, forKey: "gid")
        groupName = try container.decodeIfPresent(String.self, forKey: "n")
        propertiesVersion = try container.decode(Int.self, forKey: "pv")
        groupVersion = try container.decode(String.self, forKey: "gv")
        
        // IMMessage
        threadIdentifier = try container.decodeIfPresent(String.self, forKey: "tg")
        participants = try container.decode([String].self, forKey: "p")
        associatedMessageGUID = try container.decodeIfPresent(String.self, forKey: "amk")
        textContent = try container.decode(String.self, forKey: "t")
        associatedMessageType = try container.decodeIfPresent(IMMessageAssociationType.self, forKey: "amt")
        associatedMessageLowerBound = try container.decodeIfPresent(Int.self, forKey: "amrlc")
        pluginMessage = try? IMPluginMessage(from: decoder)
        protocolVersion = try container.decode(String.self, forKey: "v")
        associatedMessageUpperBound = try container.decodeIfPresent(Int.self, forKey: "amrln")
        replyToGUID = try container.decode(String.self, forKey: "r")
        richContent = try container.decodeIfPresent(String.self, forKey: "x")
        messageSummaryInfo = try container.decodeIfPresent(Data.self, forKey: "msi")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMBaseMessage
        try container.encode(groupID, forKey: "gid")
        try container.encodeIfPresent(groupName, forKey: "n")
        try container.encode(propertiesVersion, forKey: "pv")
        try container.encode(groupVersion, forKey: "gv")
        
        // IMMessage
        try container.encodeIfPresent(threadIdentifier, forKey: "tg")
        try container.encode(participants, forKey: "p")
        try container.encodeIfPresent(associatedMessageGUID, forKey: "amk")
        try container.encode(textContent, forKey: "t")
        try container.encodeIfPresent(associatedMessageType, forKey: "amt")
        try container.encodeIfPresent(associatedMessageLowerBound, forKey: "amrlc")
        try pluginMessage?.encode(to: encoder)
        try container.encode(protocolVersion, forKey: "v")
        try container.encodeIfPresent(associatedMessageUpperBound, forKey: "amrln")
        try container.encode(replyToGUID, forKey: "r")
        try container.encodeIfPresent(richContent, forKey: "x")
        try container.encodeIfPresent(messageSummaryInfo, forKey: "msi")
    }
}
```

`amk`, `amt`, `amrlc`, and `amrln` are all optionally encoded and decoded, and despite their co-existing properties, one's presence will not guarantee the others in the eyes of Swifts type system. On the other hand, with type aggregates, you'll get code like this:

```swift
struct IMMessage: IMBaseMessage { 
    /// The incrementing number correlated to the chat properties revision history.
    var propertiesVersion: Int
    /// The name of this group chat, if set. If it missing, the group is no longer named.
    var groupName: String?
    /// The unique identifier of this conversation.
    var groupID: String
    /// The group protocol version, which should always be 8.
    var groupVersion: String
    /// If present, provides the plugin payload.
    var pluginMessage: IMPluginMessage?
    /// If present, identifies the message this message should be correlated to.
    var messageAssociation: IMMessageAssociation?
    /// The base protocol version, which should always be 1.
    var protocolVersion: String
    /// When present, this message is in reply to another message.
    var threadIdentifier: String?
    /// Human-readable message text, can be used as a fallback text or the default if no other message formats are provided.
    var textContent: String
    /// The participants this message has been sent to.
    var participants: [String]
    /// HTML-based rich text for this message
    var richContent: String?
    /// A binary property list with additional information about this message.
    var messageSummaryInfo: Data?
    /// The GUID of the message prior to this one
    var replyToGUID: String
}

struct IMMessageAssociation { 
    /// The GUID of the message this message is associated with.
    var associatedMessageGUID: String
    /// In a rich message, the last character (as in an attributed string) that is part of the association.
    var associatedMessageUpperBound: Int
    /// The type of associated message being sent.
    var associatedMessageType: Int
    /// In a rich message, the first character (as in an attributed string) that is part of the association.
    var associatedMessageLowerBound: Int
}

extension IMMessage: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMBaseMessage
        propertiesVersion = try container.decode(Int.self, forKey: "pv")
        groupName = try container.decodeIfPresent(String.self, forKey: "n")
        groupID = try container.decode(String.self, forKey: "gid")
        groupVersion = try container.decode(String.self, forKey: "gv")
        
        // IMMessage
        pluginMessage = try? IMPluginMessage(from: decoder)
        messageAssociation = try? IMMessageAssociation(from: decoder)
        protocolVersion = try container.decode(String.self, forKey: "v")
        threadIdentifier = try container.decodeIfPresent(String.self, forKey: "tg")
        textContent = try container.decode(String.self, forKey: "t")
        participants = try container.decode([String].self, forKey: "p")
        richContent = try container.decodeIfPresent(String.self, forKey: "x")
        messageSummaryInfo = try container.decodeIfPresent(Data.self, forKey: "msi")
        replyToGUID = try container.decode(String.self, forKey: "r")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMBaseMessage
        try container.encode(propertiesVersion, forKey: "pv")
        try container.encodeIfPresent(groupName, forKey: "n")
        try container.encode(groupID, forKey: "gid")
        try container.encode(groupVersion, forKey: "gv")
        
        // IMMessage
        try pluginMessage?.encode(to: encoder)
        try messageAssociation?.encode(to: encoder)
        try container.encode(protocolVersion, forKey: "v")
        try container.encodeIfPresent(threadIdentifier, forKey: "tg")
        try container.encode(textContent, forKey: "t")
        try container.encode(participants, forKey: "p")
        try container.encodeIfPresent(richContent, forKey: "x")
        try container.encodeIfPresent(messageSummaryInfo, forKey: "msi")
        try container.encode(replyToGUID, forKey: "r")
    }
}

extension IMMessageAssociation: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMMessageAssociation
        associatedMessageGUID = try container.decode(String.self, forKey: "amk")
        associatedMessageUpperBound = try container.decode(Int.self, forKey: "amrln")
        associatedMessageType = try container.decode(Int.self, forKey: "amt")
        associatedMessageLowerBound = try container.decode(Int.self, forKey: "amrlc")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMMessageAssociation
        try container.encode(associatedMessageGUID, forKey: "amk")
        try container.encode(associatedMessageUpperBound, forKey: "amrln")
        try container.encode(associatedMessageType, forKey: "amt")
        try container.encode(associatedMessageLowerBound, forKey: "amrlc")
    }
}
```

Type aggregates are an essential part of Speck, and allow you to craft logical type representations from minified payloads.

## Type Mashing

Type mashing is the process of deduplicating and deep-merging your imported data, creating supertypes that represent your data.

This is how type mashing works:

1. You pass along an array of types, either parsed from the filesystem or retrieved from an importer.
2. These types are then "pushed" through the pipeline, where the annotation processor recursively searches nodes for annotations and applies all processors that claim said annotations. During processing, types are searched for type groups and are aggregated into a collection of occurrances for all properties.
3. Annotation processors may generate new types and replace existing types, which then need to be pushed as well. These are recursively processed until the annotation processors no longer generate new types, as they will strip the annotations from the types as they are processed.
4. Data aggregated for type groups is flattened, deep-merged, and stored into a type that is stored as a finished product.
5. The type masher finishes, with all of the generated types stored in `types`. These types may encompass enumerations, objects, protocols/interfaces, and typealiases.

### A note on annotations

You can, and are encouraged to, add your own annotations to Speck that suit your projects needs. Annotations allow you to create powerful macros and common behavior among types, and create code that is more personalized to your project without writing extensive amounts of YAML. Simply define a class that conforms to `AnnotationProcessor`, then register it in the `AnnotationRegistry`. Types that yield your annotations will automatically flow through your processor.

There are currently three annotatino processors that are built in, and the rest of the annotations are used during codegen.

- `EnumSynthesisParser` - this detects the usage of `ericrabil.com/open-enumeration` and `ericrabil.com/closed-enumeration`, and generates a SpecEnumeration from it. The type declaring this annotation will be replaced with a SpecAlias pointing to the generated enumeration. This processor is registered by default.

```yaml
annotations:
    ericrabil.com/closed-enumeration: |
      kind: String
      name: IMGroupMessageUpdateType
      cases:
        nameChange: n
        participantChange: p
        photoChange: v
```

The declaring type will be overwritten with an alias to `IMGroupMessageUpdateType`, and a closed enum will be pushed into the global type namespace.

- `TypeLiftingProcessor` – this detects the usage of `ericrabil.com/extracted-type-name`, and rips out the type and all of its descendents into a root type whose name corresponds to the annotation value. The declaring type will be overwritten with an alias pointing to the generated root type. This processor is registered by default.

- `_TypeGroupProcessor` – underscored, used as part of type group collection. All types who declare this are captured and processed at the end of the recursion, where they are deep-merged from left to right and then assembled into a root type. This is an internal processor that is always injected.

## Transpilation

Transpilation is wholly implementation-specific, as is any programming language. There is a reference generator for Swift which utilizes the SwiftSyntax library. Generally, you can subclass the `SpecMasher` class, pass a set of types to it, and then transpile the `types` value to code as you wish.

---

## CoreSpeck API

CoreSpeck comes with a Standard Specification, or `stdspec`, which offers types for representing objects, array, dictionaries, enumerations, primitives, and type aliases. This is separate from the Specification definition, which is merely a set of protocols and lightweight classes for the runtime. You can technically create your own standard spec, though you'd sacrifice a lot of first-class annotations in the process, as they specialize to certain spec types.

All SpecTypes provide at least two values: their kind, and their metadata. These are guaranteed to be both present and consistent, as they are required for successfully performing type processing. SpecTypes can encompass multiple kinds, but multiple SpecTypes cannot encompass the same kinds. **There can be only one.**

The following specs are provided in the stdspec:

### SpecPrimitive

The SpecPrimitive represents a primitive, terminal point in your types. The following are supported by the stdspec:

- String
- Integer
- Double
- Boolean
- Never (tombstone type)
- Date
- Data

As primitives are SpecTypes, they too may yield metadata.

```swift
/// Lowest-level representation a spec can yield
public enum SpecPrimitive {
    public enum Kind: String, Codable {
        case string = "String"
        case integer = "Integer"
        case double = "Double"
        case bool = "Boolean"
        case never = "Never"
        case date = "Date"
        case data = "Data"
    }

    case string(SpecMetadata)
    case integer(SpecMetadata)
    case double(SpecMetadata)
    case bool(SpecMetadata)
    case never(SpecMetadata)
    case date(SpecMetadata)
    case data(SpecMetadata)
    
    public var primitiveKind: Kind { get set }
    public var metadata: SpecMetadata { get set }
}

var primitive: SpecPrimitive = ...

primitive.primitiveKind = .double
primitive.metadata.description = "A double!!?"
```

The above primitive would have the following YAML representation:

```yaml
kind: Primitive
type: Double
metadata:
    description: "A double!!?"
```

SpecTypes with empty metadata will not have a metadata entry, so if we didn't assign a description, we'd get this instead:

```yaml
kind: Primitive
type: Double
```

### SpecAlias

A SpecAlias allows you to reference another named type, rather than declaring your own structure. They carry around the alias name, the aliasee name, and the aliasee kind. In code generation it is expected that the aliasee name be used as the type, rather than the underlying type.

```swift
let alias = SpecAlias(name: "MyAlias", aliasedName: "SomeOtherType", aliasedKind: .object)
```

```yaml
kind: Reference
name: MyAlias
aliasedName: SomeOtherType
aliasedKind: Object
```

If you were to generate this to swift, you'd see this:

```
var property: SomeOtherType
```

### SpecCluster

A cluster is a group of same-typed values, either in the form of an array or a dictionary. It is your responsibility to ensure that, in dictionaries, the key value is actually able to be a key. This is not a type checking system, it is a generation system. It does what you tell it to.

```swift
public enum SpecCluster {
    case array(element: SpecType, metadata: SpecMetadata)
    case dictionary(key: SpecType, element: SpecType, metadata: SpecMetadata)
    
    var element: SpecType { get set }
    var key: SpecType? { get set } // moving from nil to non-nil converts to a dictionary, non-nil to nil to an array
    
    var isArray: Bool { get }
    var isDictionary: Bool { get }
    
    var metadata: SpecMetadata { get set }
    
    var kind: SpecKind { get } // either .array or .dictionary
}
```

```yaml
kind: Array
element:
    kind: Primitive
    type: String
```

```yaml
kind: Dictionary
key:
    kind: Primitive
    type: String
element:
    kind: Primitive
    type: String
```

### SpecNode

A SpecNode is an object of mixed key-value content. It is most commonly used to represent classes, structs, and protocols.

```swift
public class SpecNode {
    public var name: String
    public var children: [String: SpecType]
    public var metadata: SpecMetadata
}
```

```yaml
kind: Object
name: IMMessage
metadata:
    description: "Represents a singular message"
children:
    guid:
        kind: Primitive
        type: String
    participants:
        kind: Array
        element:
            kind: Primitive
            type: String
```

```swift
/// Represents a singular message
struct IMMessage {
    var guid: String
    var participants: [String]
}
```

### SpecEnumeration

A SpecEnumeration corresponds to an enum type, and is constricted to primitive types. Support for associated-value enums is not present at this time, though could easily be achieved through a new spec for documenting an associatied value.

```swift
public class SpecEnumeration {
    /// The name of this enumeration
    public var name: String
    
    /// Whether there are additional, unknown potential values
    public var extensible: Bool
    
    public var metadata: SpecMetadata
    public var enumerationKind: SpecPrimitive.Kind
    
    /// Though these are String:String, generators will render their case values differently depending on their primitive kind. I.e. strings will get quotes, numbers will be unwrapped, etc.
    public var cases: [String: String]
}
```

```yaml
kind: Enumeration
enumerationKind: Integer
name: IMMessageAssociationType
cases:
    unspecified: 0
    edit: 1
    unconsumed: 2
    consumed: 4
    sticker: 1000
    heart: 2000
    thumbsUp: 2001
    thumbsDown: 2002
    ha: 2003
    exclamation: 2004
    questionMark: 2005
    deselectedHeart: 3000
    deselectedThumbsUp: 3001
    deselectedThumbsDown: 3002
    deselectedHa: 3003
    deselectedExclamation: 3004
    deselectedQuestionMark: 3005
```

```swift
enum IMMessageAssociationType: Int {
    case consumed = 4
    case ha = 2003
    case thumbsUp = 2001
    case sticker = 1000
    case exclamation = 2004
    case thumbsDown = 2002
    case deselectedThumbsUp = 3001
    case deselectedExclamation = 3004
    case edit = 1
    case questionMark = 2005
    case deselectedHa = 3003
    case deselectedHeart = 3000
    case heart = 2000
    case unspecified = 0
    case unconsumed = 2
    case deselectedThumbsDown = 3002
    case deselectedQuestionMark = 3005
}
```

### TypeGroup
A TypeGroup is a specialized type which does not get converted to code. Rather, it serves as a sidecar to provide additional metadata for existing type groups, in order to control code generation.

```swift
public class TypeGroup {
    public enum GenerationStyle: String, Codable {
        case concrete = "Concrete"
        case abstract = "Abstract"
    }
    
    public struct Settings: Codable {
        /// Whether to generate as an interface (protocol) or concrete type (struct/class)
        public var generationStyle: GenerationStyle
        /// Similar to implementing an interface, will include all of the defined entries in property and de/serialization synthesis.
        public var explicitlyExtends: [String]
    }
    
    public var name: String
    public var settings: Settings
    public var metadata: SpecMetadata
}
}
```

The name of the TypeGroup is used to find a SpecNode with the same name. If one is present, its generation is modulated by the settings defined in the TypeGroup.

```yaml
kind: TypeGroup
name: IMBaseMessage
settings:
  generationStyle: Abstract
---
kind: TypeGroup
name: IMGroupMessage
settings:
  explicitlyExtends:
    - IMBaseMessage
---
kind: TypeGroup
name: IMMessage
settings:
  explicitlyExtends:
    - IMBaseMessage
```

This set of type groups declares a common ancestor IMBaseMessage between IMGroupMessage and IMMessage. Because IMBaseMessage is abstract, it will be generated as a protocol/interface type. IMGroupMessage and IMMessage will include IMBaseMessage's properties and serialization as if it was declared within IMGroupMessage and IMMessage.

### SpecCustomization

Customizations are heavily inspired by Kustomize, so you should take a look there for additional clarifications. They support the following operations:

- add
- replace
- remove
- append

In the event a patch target does not have the value you are trying to patch, you can specify to skip it via missingBehavior. This is useful for when a value is optionally defined, but has no other suitable or convenient target.

```swift
public struct CustomizationPatch: Equatable {
    public enum PatchType: String, Codable, Hashable, Equatable {
        case add, replace, remove, append
    }
    
    public enum MissingBehavior: String, Codable, Hashable, Equatable {
        case skip, `throw`
    }
    
    public var operation: PatchType
    public var path: String
    public var missingBehavior: MissingBehavior
    
    public var metadata: SpecMetadata
    public var value: Node?
}

public struct CustomizationTarget: Equatable {
    public var kind: String?
    public var name: String?
    public var metadata: SpecMetadata?
    public var hashes: [String]? // a target can specify multiple hashes to apply patch to multiple models
    public var children: [Node.Mapping]?
}

public struct SpecCustomization: Codable, Equatable {
    public var target: CustomizationTarget
    public var patches: [CustomizationPatch]
    public var name: String
}
```

This customization targets payloads who have either a value `type` whose type is a string, or a value `p` whose type is [String]. It then applies a series of patches which add documentation and annotations to the grouped properties. Note that these properties are being assigned type groups, which will automatically generate a type group for them. This allows you to write a customization that groups together common values from a set of imported data.

```yaml
kind: Customization
name: IMMessageBaseAnnotations
target:
  children:
    - |
      type:
        kind: Primitive
        type: String
    - |
      p:
        kind: Array
        element:
          kind: Primitive
          type: String
patches:
  - op: add
    path: /children/n/metadata
    missing-behavior: skip
    value:
      annotations:
        ericrabil.com/readable-name: groupName
        ericrabil.com/type-group: IMBaseMessage
        ericrabil.com/value-nullable: true
      description: The name of this group chat, if set. If it missing, the group is no longer named.
  - op: add
    path: /children/gid/metadata
    value:
      annotations:
        ericrabil.com/readable-name: groupID
        ericrabil.com/type-group: IMBaseMessage
      description: The unique identifier of this conversation.
  - op: add
    path: /children/pv/metadata
    value:
      annotations:
        ericrabil.com/readable-name: propertiesVersion
        ericrabil.com/type-group: IMBaseMessage
      description: The incrementing number correlated to the chat properties revision history.
  - op: add
    path: /children/gv/metadata
    value:
      annotations:
        ericrabil.com/readable-name: groupVersion
        ericrabil.com/require-constant: "8"
        ericrabil.com/type-group: IMBaseMessage
      description: The group protocol version, which should always be 8.
```

---

## Example

You can see Speck in action in the [Example](Example) directory. Here's a breakdown of its contents:

- [iMessageSpeck](Example/iMessageSpeck) contains a set of raw types generated by the XMLImporter. I dumped XML-encoded plists of my messages for 48 hours, and then deleted all duplicate types.
- [iMessageCustomizations](Example/iMessageCustomizations) contains a set of customizations to apply that will bring cohesiveness to these types.
- [iMessageGenerations](Example/iMessageGenerations) contains a final set of types that were mashed together following annotation processing. These specs can then be passed to a transpiler to create types in any language.
- [swiftgen.swift](Example/swiftgen.swift) contains the generated swift code from the iMessageGenerations.
