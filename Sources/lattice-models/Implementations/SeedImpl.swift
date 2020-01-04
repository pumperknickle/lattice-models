import Foundation
import Bedrock

public struct SeedImpl: Codable {
    private let rawDirectory: String!
    private let rawDigest: Digest!
    private let rawOldSeed: SendableImpl?
    private let rawNewSeed: SendableImpl!
    public init(directory: String, digest: Digest, oldSeed: SendableImpl?, newSeed: SendableImpl) {
        rawDirectory = directory
        rawDigest = digest
        rawOldSeed = oldSeed
        rawNewSeed = newSeed
    }
}

extension SeedImpl: ActionEncodable {
    public typealias ActionType = ActionImpl
}

extension SeedImpl: Seed {
    public typealias Digest = UInt256
    public typealias SendableType = SendableImpl
    
    public var directory: String { return rawDirectory }
    public var digest: Digest { return rawDigest }
    public var oldSeed: SendableImpl? { return rawOldSeed }
    public var newSeed: SendableImpl { return rawNewSeed }
}
