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

struct IMGroupPhotoTransfer { 
	/// The GUID of the file transfer for this group photo.
	var guid: String
	/// The GUID of the message changing the group photo.
	var messageGUID: String?
	/// The user info for the photo being transferred.
	var localUserInfo: IMGroupPhotoTransferUserInfo?
	/// The time the group photo change was initiated.
	var createdDate: Double
	/// The UTI type of the group photo.
	var utiType: String?
	/// The name of the group photo being transferred.
	var filename: String
}
struct IMPluginMessagePayloadInformation { 
	/// The signature provided by the sender to validate the incoming data.
	var signature: Data
	/// The owner of this payload data
	var owner: String
	/// The owner of this payload data
	var url: String
	/// The decryption key that will be used to unarchive the incoming data.
	var decryptionKey: Data
	/// The size in bytes of the incoming data.
	var size: Int
}
struct IMMessage: IMBaseMessage { 
	/// The incrementing number correlated to the chat properties revision history.
	var propertiesVersion: Int
	/// The name of this group chat, if set. If it missing, the group is no longer named.
	var groupName: String?
	/// The unique identifier of this conversation.
	var groupID: String
	/// The group protocol version, which should always be 8.
	var groupVersion: String
	/// If present, identifies the message this message should be correlated to.
	var messageAssociation: IMMessageAssociation?
	/// The participants this message has been sent to.
	var participants: [String]
	/// HTML-based rich text for this message
	var richContent: String?
	/// A binary property list with additional information about this message.
	var messageSummaryInfo: Data?
	/// Human-readable message text, can be used as a fallback text or the default if no other message formats are provided.
	var textContent: String
	/// When present, this message is in reply to another message.
	var threadIdentifier: String?
	/// The base protocol version, which should always be 1.
	var protocolVersion: String
	/// If present, provides the plugin payload.
	var pluginMessage: IMPluginMessage?
	/// The GUID of the message prior to this one
	var replyToGUID: String
}
protocol IMBaseMessage { 
	/// The incrementing number correlated to the chat properties revision history.
	var propertiesVersion: Int { get set }
	/// The name of this group chat, if set. If it missing, the group is no longer named.
	var groupName: String? { get set }
	/// The unique identifier of this conversation.
	var groupID: String { get set }
	/// The group protocol version, which should always be 8.
	var groupVersion: String { get set }
}
struct IMMessageAssociation { 
	/// In a rich message, the last character (as in an attributed string) that is part of the association.
	var associatedMessageUpperBound: Int
	/// In a rich message, the first character (as in an attributed string) that is part of the association.
	var associatedMessageLowerBound: Int
	/// The type of associated message being sent.
	var associatedMessageType: IMMessageAssociationType
	/// The GUID of the message this message is associated with.
	var associatedMessageGUID: String
}
struct IMPluginMessage { 
	/// The payload data to pass to the balloon plugin payload responsible for this message.
	var balloonPluginPayload: Data?
	/// The bundle identifier of the balloon plugin responsible for this message.
	var ballooonPluginID: String
	var balloonPluginPayloadInformation: IMPluginMessagePayloadInformation?
}
struct IMGroupPhotoTransferUserInfo { 
	/// The identifier of the sender of this transfer.
	var owner: String
	/// The date on which this transfer will need to be refreshed.
	var refreshDate: Date
	/// The size in bytes of this transfer.
	var fileSize: String
	/// The signature sent by the sender of this transfer.
	var signatureHex: String
	/// The key to be used when decrypting this transfer.
	var decryptionKey: String
	/// The URL at which this transfer can be downloaded.
	var url: String
}
struct IMGroupMessage: IMBaseMessage { 
	/// The incrementing number correlated to the chat properties revision history.
	var propertiesVersion: Int
	/// The name of this group chat, if set. If it missing, the group is no longer named.
	var groupName: String?
	/// The unique identifier of this conversation.
	var groupID: String
	/// The group protocol version, which should always be 8.
	var groupVersion: String
	/// The participants this group change was sent to.
	var senderParticipants: [String]
	/// A file transfer for the new group photo.
	var groupPhotoTransfer: IMGroupPhotoTransfer?
	/// When present, the group should now be named this value.
	var newGroupName: String?
	/// The type of change being made. One of (n,p,v)
	var groupUpdateType: IMGroupMessageUpdateType
	/// When present, the group now has the participants within this value.
	var toParticipants: [String]?
}
enum IMGroupMessageUpdateType: String, Codable { 
	case nameChange = "n"
	case participantChange = "p"
	case photoChange = "v"
}
enum IMMessageAssociationType: Int, Codable { 
	case exclamation = 2004
	case edit = 1
	case thumbsUp = 2001
	case ha = 2003
	case consumed = 4
	case deselectedThumbsUp = 3001
	case deselectedExclamation = 3004
	case deselectedQuestionMark = 3005
	case deselectedHa = 3003
	case unspecified = 0
	case deselectedHeart = 3000
	case heart = 2000
	case thumbsDown = 2002
	case questionMark = 2005
	case sticker = 1000
	case unconsumed = 2
	case deselectedThumbsDown = 3002
}
extension IMGroupPhotoTransfer: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
		
		// IMGroupPhotoTransfer
		guid = try container.decode(String.self, forKey: "IMFileTransferGUID")
		messageGUID = try container.decodeIfPresent(String.self, forKey: "IMFileTransferMessageGUID")
		localUserInfo = try container.decodeIfPresent(IMGroupPhotoTransferUserInfo.self, forKey: "IMFileTransferLocalUserInfoKey")
		createdDate = try container.decode(Double.self, forKey: "IMFileTransferCreatedDate")
		utiType = try container.decodeIfPresent(String.self, forKey: "IMFileTransferUTITypeKey")
		filename = try container.decode(String.self, forKey: "IMFileTransferFilenameKey")
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
		
		// IMGroupPhotoTransfer
		try container.encode(guid, forKey: "IMFileTransferGUID")
		try container.encodeIfPresent(messageGUID, forKey: "IMFileTransferMessageGUID")
		try container.encodeIfPresent(localUserInfo, forKey: "IMFileTransferLocalUserInfoKey")
		try container.encode(createdDate, forKey: "IMFileTransferCreatedDate")
		try container.encodeIfPresent(utiType, forKey: "IMFileTransferUTITypeKey")
		try container.encode(filename, forKey: "IMFileTransferFilenameKey")
	}
}
extension IMGroupMessage: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
		
		// IMBaseMessage
		propertiesVersion = try container.decode(Int.self, forKey: "pv")
		groupName = try container.decodeIfPresent(String.self, forKey: "n")
		groupID = try container.decode(String.self, forKey: "gid")
		groupVersion = try container.decode(String.self, forKey: "gv")
		
		// IMGroupMessage
		senderParticipants = try container.decode([String].self, forKey: "sp")
		groupPhotoTransfer = try container.decodeIfPresent(IMGroupPhotoTransfer.self, forKey: "tv")
		newGroupName = try container.decodeIfPresent(String.self, forKey: "nn")
		groupUpdateType = try container.decode(IMGroupMessageUpdateType.self, forKey: "type")
		toParticipants = try container.decodeIfPresent([String].self, forKey: "tp")
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
		
		// IMBaseMessage
		try container.encode(propertiesVersion, forKey: "pv")
		try container.encodeIfPresent(groupName, forKey: "n")
		try container.encode(groupID, forKey: "gid")
		try container.encode(groupVersion, forKey: "gv")
		
		// IMGroupMessage
		try container.encode(senderParticipants, forKey: "sp")
		try container.encodeIfPresent(groupPhotoTransfer, forKey: "tv")
		try container.encodeIfPresent(newGroupName, forKey: "nn")
		try container.encode(groupUpdateType, forKey: "type")
		try container.encodeIfPresent(toParticipants, forKey: "tp")
	}
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
		messageAssociation = try? IMMessageAssociation(from: decoder)
		participants = try container.decode([String].self, forKey: "p")
		richContent = try container.decodeIfPresent(String.self, forKey: "x")
		messageSummaryInfo = try container.decodeIfPresent(Data.self, forKey: "msi")
		textContent = try container.decode(String.self, forKey: "t")
		threadIdentifier = try container.decodeIfPresent(String.self, forKey: "tg")
		protocolVersion = try container.decode(String.self, forKey: "v")
		pluginMessage = try? IMPluginMessage(from: decoder)
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
		try messageAssociation?.encode(to: encoder)
		try container.encode(participants, forKey: "p")
		try container.encodeIfPresent(richContent, forKey: "x")
		try container.encodeIfPresent(messageSummaryInfo, forKey: "msi")
		try container.encode(textContent, forKey: "t")
		try container.encodeIfPresent(threadIdentifier, forKey: "tg")
		try container.encode(protocolVersion, forKey: "v")
		try pluginMessage?.encode(to: encoder)
		try container.encode(replyToGUID, forKey: "r")
	}
}
extension IMPluginMessage: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
		
		// IMPluginMessage
		balloonPluginPayload = try container.decodeIfPresent(Data.self, forKey: "bp")
		ballooonPluginID = try container.decode(String.self, forKey: "bid")
		balloonPluginPayloadInformation = try container.decodeIfPresent(IMPluginMessagePayloadInformation.self, forKey: "bpdi")
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
		
		// IMPluginMessage
		try container.encodeIfPresent(balloonPluginPayload, forKey: "bp")
		try container.encode(ballooonPluginID, forKey: "bid")
		try container.encodeIfPresent(balloonPluginPayloadInformation, forKey: "bpdi")
	}
}
extension IMGroupPhotoTransferUserInfo: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
		
		// IMGroupPhotoTransferUserInfo
		owner = try container.decode(String.self, forKey: "mmcs-owner")
		refreshDate = try container.decode(Date.self, forKey: "refresh-date")
		fileSize = try container.decode(String.self, forKey: "file-size")
		signatureHex = try container.decode(String.self, forKey: "mmcs-signature-hex")
		decryptionKey = try container.decode(String.self, forKey: "decryption-key")
		url = try container.decode(String.self, forKey: "mmcs-url")
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
		
		// IMGroupPhotoTransferUserInfo
		try container.encode(owner, forKey: "mmcs-owner")
		try container.encode(refreshDate, forKey: "refresh-date")
		try container.encode(fileSize, forKey: "file-size")
		try container.encode(signatureHex, forKey: "mmcs-signature-hex")
		try container.encode(decryptionKey, forKey: "decryption-key")
		try container.encode(url, forKey: "mmcs-url")
	}
}
extension IMPluginMessagePayloadInformation: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
		
		// IMPluginMessagePayloadInformation
		signature = try container.decode(Data.self, forKey: "s")
		owner = try container.decode(String.self, forKey: "o")
		url = try container.decode(String.self, forKey: "r")
		decryptionKey = try container.decode(Data.self, forKey: "e")
		size = try container.decode(Int.self, forKey: "f")
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
		
		// IMPluginMessagePayloadInformation
		try container.encode(signature, forKey: "s")
		try container.encode(owner, forKey: "o")
		try container.encode(url, forKey: "r")
		try container.encode(decryptionKey, forKey: "e")
		try container.encode(size, forKey: "f")
	}
}
extension IMMessageAssociation: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: StringLiteralCodingKey.self)
		
		// IMMessageAssociation
		associatedMessageUpperBound = try container.decode(Int.self, forKey: "amrln")
		associatedMessageLowerBound = try container.decode(Int.self, forKey: "amrlc")
		associatedMessageType = try container.decode(IMMessageAssociationType.self, forKey: "amt")
		associatedMessageGUID = try container.decode(String.self, forKey: "amk")
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
		
		// IMMessageAssociation
		try container.encode(associatedMessageUpperBound, forKey: "amrln")
		try container.encode(associatedMessageLowerBound, forKey: "amrlc")
		try container.encode(associatedMessageType, forKey: "amt")
		try container.encode(associatedMessageGUID, forKey: "amk")
	}
}
