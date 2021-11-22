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

public struct IMGroupPhotoTransfer: Hashable, Equatable {
    /// The time the group photo change was initiated.
    public var createdDate: Double
    /// The UTI type of the group photo.
    public var utiType: String?
    /// The GUID of the message changing the group photo.
    public var messageGUID: String?
    /// The GUID of the file transfer for this group photo.
    public var guid: String
    /// The name of the group photo being transferred.
    public var filename: String
    /// The user info for the photo being transferred.
    public var localUserInfo: IMGroupPhotoTransferUserInfo?
}
public struct IMGroupPhotoTransferUserInfo: Hashable, Equatable {
    /// The date on which this transfer will need to be refreshed.
    public var refreshDate: Date
    /// The key to be used when decrypting this transfer.
    public var decryptionKey: String
    /// The identifier of the sender of this transfer.
    public var owner: String
    /// The size in bytes of this transfer.
    public var fileSize: String
    /// The signature sent by the sender of this transfer.
    public var signatureHex: String
    /// The URL at which this transfer can be downloaded.
    public var url: String
}
public struct IMGroupMessage: Hashable, Equatable, IMBaseMessage {
    /// The unique identifier of this conversation.
    public var groupID: String
    /// The incrementing number correlated to the chat properties revision history.
    public var propertiesVersion: Int
    /// The name of this group chat, if set. If it missing, the group is no longer named.
    public var groupName: String?
    /// The group protocol version, which should always be 8.
    public var groupVersion: String
    /// The participants this group change was sent to.
    public var senderParticipants: [String]
    /// When present, the group should now be named this value.
    public var newGroupName: String?
    /// When present, the group now has the participants within this value.
    public var toParticipants: [String]?
    /// A file transfer for the new group photo.
    public var groupPhotoTransfer: IMGroupPhotoTransfer?
    /// The type of change being made. One of (n,p,v)
    public var groupUpdateType: IMGroupMessageUpdateType
}
public struct IMPluginMessage: Hashable, Equatable {
    /// The bundle identifier of the balloon plugin responsible for this message.
    public var ballooonPluginID: String
    /// The payload data to pass to the balloon plugin payload responsible for this message.
    public var balloonPluginPayload: Data?
    public var balloonPluginPayloadInformation: IMPluginMessagePayloadInformation?
}
public struct IMMessageAssociation: Hashable, Equatable {
    /// The type of associated message being sent.
    public var associatedMessageType: IMMessageAssociationType
    /// In a rich message, the first character (as in an attributed string) that is part of the association.
    public var associatedMessageLowerBound: Int
    /// In a rich message, the last character (as in an attributed string) that is part of the association.
    public var associatedMessageUpperBound: Int
    /// The GUID of the message this message is associated with.
    public var associatedMessageGUID: String
}
public struct IMPluginMessagePayloadInformation: Hashable, Equatable {
    /// The size in bytes of the incoming data.
    public var size: Int
    /// The signature provided by the sender to validate the incoming data.
    public var signature: Data
    /// The decryption key that will be used to unarchive the incoming data.
    public var decryptionKey: Data
    /// The owner of this payload data
    public var url: String
    /// The owner of this payload data
    public var owner: String
}
public struct IMMessage: Hashable, Equatable, IMBaseMessage {
    /// The unique identifier of this conversation.
    public var groupID: String
    /// The incrementing number correlated to the chat properties revision history.
    public var propertiesVersion: Int
    /// The name of this group chat, if set. If it missing, the group is no longer named.
    public var groupName: String?
    /// The group protocol version, which should always be 8.
    public var groupVersion: String
    /// A binary property list with additional information about this message.
    public var messageSummaryInfo: Data?
    /// The base protocol version, which should always be 1.
    public var protocolVersion: String
    /// When present, this message is in reply to another message.
    public var threadIdentifier: String?
    /// The GUID of the message prior to this one
    public var replyToGUID: String
    /// The participants this message has been sent to.
    public var participants: [String]
    /// If present, provides the plugin payload.
    public var pluginMessage: IMPluginMessage?
    /// Human-readable message text, can be used as a fallback text or the default if no other message formats are provided.
    public var textContent: String
    /// If present, identifies the message this message should be correlated to.
    public var messageAssociation: IMMessageAssociation?
    /// HTML-based rich text for this message
    public var richContent: String?
}
public protocol IMBaseMessage {
    /// The unique identifier of this conversation.
    var groupID: String { get set }
    /// The incrementing number correlated to the chat properties revision history.
    var propertiesVersion: Int { get set }
    /// The name of this group chat, if set. If it missing, the group is no longer named.
    var groupName: String? { get set }
    /// The group protocol version, which should always be 8.
    var groupVersion: String { get set }
}
public enum IMMessageAssociationType: Int, Codable, Equatable, Hashable {
    case deselectedQuestionMark = 3005
    case exclamation = 2004
    case deselectedHeart = 3000
    case consumed = 4
    case deselectedHa = 3003
    case unconsumed = 2
    case thumbsUp = 2001
    case edit = 1
    case heart = 2000
    case unspecified = 0
    case sticker = 1000
    case thumbsDown = 2002
    case deselectedThumbsDown = 3002
    case ha = 2003
    case questionMark = 2005
    case deselectedThumbsUp = 3001
    case deselectedExclamation = 3004
}
public enum IMGroupMessageUpdateType: String, Codable, Equatable, Hashable {
    case nameChange = "n"
    case participantChange = "p"
    case photoChange = "v"
}
extension IMMessage: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMBaseMessage
        groupID = try container.decode(String.self, forKey: "gid")
        propertiesVersion = try container.decode(Int.self, forKey: "pv")
        groupName = try container.decodeIfPresent(String.self, forKey: "n")
        groupVersion = try container.decode(String.self, forKey: "gv")
        
        // IMMessage
        messageSummaryInfo = try container.decodeIfPresent(Data.self, forKey: "msi")
        protocolVersion = try container.decode(String.self, forKey: "v")
        threadIdentifier = try container.decodeIfPresent(String.self, forKey: "tg")
        replyToGUID = try container.decode(String.self, forKey: "r")
        participants = try container.decode([String].self, forKey: "p")
        pluginMessage = try? IMPluginMessage(from: decoder)
        textContent = try container.decode(String.self, forKey: "t")
        messageAssociation = try? IMMessageAssociation(from: decoder)
        richContent = try container.decodeIfPresent(String.self, forKey: "x")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMBaseMessage
        try container.encode(groupID, forKey: "gid")
        try container.encode(propertiesVersion, forKey: "pv")
        try container.encodeIfPresent(groupName, forKey: "n")
        try container.encode(groupVersion, forKey: "gv")
        
        // IMMessage
        try container.encodeIfPresent(messageSummaryInfo, forKey: "msi")
        try container.encode(protocolVersion, forKey: "v")
        try container.encodeIfPresent(threadIdentifier, forKey: "tg")
        try container.encode(replyToGUID, forKey: "r")
        try container.encode(participants, forKey: "p")
        try pluginMessage?.encode(to: encoder)
        try container.encode(textContent, forKey: "t")
        try messageAssociation?.encode(to: encoder)
        try container.encodeIfPresent(richContent, forKey: "x")
    }
}
extension IMGroupPhotoTransferUserInfo: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMGroupPhotoTransferUserInfo
        refreshDate = try container.decode(Date.self, forKey: "refresh-date")
        decryptionKey = try container.decode(String.self, forKey: "decryption-key")
        owner = try container.decode(String.self, forKey: "mmcs-owner")
        fileSize = try container.decode(String.self, forKey: "file-size")
        signatureHex = try container.decode(String.self, forKey: "mmcs-signature-hex")
        url = try container.decode(String.self, forKey: "mmcs-url")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMGroupPhotoTransferUserInfo
        try container.encode(refreshDate, forKey: "refresh-date")
        try container.encode(decryptionKey, forKey: "decryption-key")
        try container.encode(owner, forKey: "mmcs-owner")
        try container.encode(fileSize, forKey: "file-size")
        try container.encode(signatureHex, forKey: "mmcs-signature-hex")
        try container.encode(url, forKey: "mmcs-url")
    }
}
extension IMGroupPhotoTransfer: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMGroupPhotoTransfer
        createdDate = try container.decode(Double.self, forKey: "IMFileTransferCreatedDate")
        utiType = try container.decodeIfPresent(String.self, forKey: "IMFileTransferUTITypeKey")
        messageGUID = try container.decodeIfPresent(String.self, forKey: "IMFileTransferMessageGUID")
        guid = try container.decode(String.self, forKey: "IMFileTransferGUID")
        filename = try container.decode(String.self, forKey: "IMFileTransferFilenameKey")
        localUserInfo = try container.decodeIfPresent(IMGroupPhotoTransferUserInfo.self, forKey: "IMFileTransferLocalUserInfoKey")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMGroupPhotoTransfer
        try container.encode(createdDate, forKey: "IMFileTransferCreatedDate")
        try container.encodeIfPresent(utiType, forKey: "IMFileTransferUTITypeKey")
        try container.encodeIfPresent(messageGUID, forKey: "IMFileTransferMessageGUID")
        try container.encode(guid, forKey: "IMFileTransferGUID")
        try container.encode(filename, forKey: "IMFileTransferFilenameKey")
        try container.encodeIfPresent(localUserInfo, forKey: "IMFileTransferLocalUserInfoKey")
    }
}
extension IMPluginMessagePayloadInformation: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMPluginMessagePayloadInformation
        size = try container.decode(Int.self, forKey: "f")
        signature = try container.decode(Data.self, forKey: "s")
        decryptionKey = try container.decode(Data.self, forKey: "e")
        url = try container.decode(String.self, forKey: "r")
        owner = try container.decode(String.self, forKey: "o")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMPluginMessagePayloadInformation
        try container.encode(size, forKey: "f")
        try container.encode(signature, forKey: "s")
        try container.encode(decryptionKey, forKey: "e")
        try container.encode(url, forKey: "r")
        try container.encode(owner, forKey: "o")
    }
}
extension IMGroupMessage: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMBaseMessage
        groupID = try container.decode(String.self, forKey: "gid")
        propertiesVersion = try container.decode(Int.self, forKey: "pv")
        groupName = try container.decodeIfPresent(String.self, forKey: "n")
        groupVersion = try container.decode(String.self, forKey: "gv")
        
        // IMGroupMessage
        senderParticipants = try container.decode([String].self, forKey: "sp")
        newGroupName = try container.decodeIfPresent(String.self, forKey: "nn")
        toParticipants = try container.decodeIfPresent([String].self, forKey: "tp")
        groupPhotoTransfer = try container.decodeIfPresent(IMGroupPhotoTransfer.self, forKey: "tv")
        groupUpdateType = try container.decode(IMGroupMessageUpdateType.self, forKey: "type")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMBaseMessage
        try container.encode(groupID, forKey: "gid")
        try container.encode(propertiesVersion, forKey: "pv")
        try container.encodeIfPresent(groupName, forKey: "n")
        try container.encode(groupVersion, forKey: "gv")
        
        // IMGroupMessage
        try container.encode(senderParticipants, forKey: "sp")
        try container.encodeIfPresent(newGroupName, forKey: "nn")
        try container.encodeIfPresent(toParticipants, forKey: "tp")
        try container.encodeIfPresent(groupPhotoTransfer, forKey: "tv")
        try container.encode(groupUpdateType, forKey: "type")
    }
}
extension IMMessageAssociation: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMMessageAssociation
        associatedMessageType = try container.decode(IMMessageAssociationType.self, forKey: "amt")
        associatedMessageLowerBound = try container.decode(Int.self, forKey: "amrlc")
        associatedMessageUpperBound = try container.decode(Int.self, forKey: "amrln")
        associatedMessageGUID = try container.decode(String.self, forKey: "amk")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMMessageAssociation
        try container.encode(associatedMessageType, forKey: "amt")
        try container.encode(associatedMessageLowerBound, forKey: "amrlc")
        try container.encode(associatedMessageUpperBound, forKey: "amrln")
        try container.encode(associatedMessageGUID, forKey: "amk")
    }
}
extension IMPluginMessage: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMPluginMessage
        ballooonPluginID = try container.decode(String.self, forKey: "bid")
        balloonPluginPayload = try container.decodeIfPresent(Data.self, forKey: "bp")
        balloonPluginPayloadInformation = try container.decodeIfPresent(IMPluginMessagePayloadInformation.self, forKey: "bpdi")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
        
        // IMPluginMessage
        try container.encode(ballooonPluginID, forKey: "bid")
        try container.encodeIfPresent(balloonPluginPayload, forKey: "bp")
        try container.encodeIfPresent(balloonPluginPayloadInformation, forKey: "bpdi")
    }
}
