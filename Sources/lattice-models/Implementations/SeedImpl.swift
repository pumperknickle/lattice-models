import Foundation
import Bedrock

public struct SeedImpl: Codable {
    private let rawDirectory: String!
    private let rawOldSeeds: [SendableImpl]?
    private let rawNewSeeds: [SendableImpl]!
    public init(directory: String, oldSeeds: [SendableImpl]?, newSeeds: [SendableImpl]) {
        rawDirectory = directory
        rawOldSeeds = oldSeeds
        rawNewSeeds = newSeeds
    }
}

extension SeedImpl: ActionEncodable {
    public typealias ActionType = ActionImpl
}

extension SeedImpl: Seed {
    public typealias SendableType = SendableImpl
    public var directory: String { return rawDirectory }
    public var oldSeeds: [SendableImpl]? { return rawOldSeeds }
    public var newSeeds: [SendableImpl] { return rawNewSeeds }
}
