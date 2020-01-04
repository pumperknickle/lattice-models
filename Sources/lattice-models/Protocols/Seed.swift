import Foundation
import Bedrock

public let SEED_PREFIX = "seed/"

public protocol Seed: Codable, ActionEncodable {
    associatedtype SendableType: Sendable
    associatedtype Digest: FixedWidthInteger, Stringable

    var directory: String { get }
    var digest: Digest { get }
    var oldSeed: SendableType? { get }
    var newSeed: SendableType { get }

    init(directory: String, digest: Digest, oldSeed: SendableType?, newSeed: SendableType)
}

public extension Seed {
    init?(action: ActionType) {
        let digestAndDirectory = String(action.key.dropFirst(SEED_PREFIX.count))
        let stringArray = digestAndDirectory.components(separatedBy: "/")
        guard let directory = stringArray.first else { return nil }
        guard let digestString = stringArray.dropFirst().first else { return nil }
        guard let digest = Digest(stringValue: digestString) else { return nil }
        if stringArray.count != 2 { return nil }
        guard let new = action.new else { return nil }
        guard let newSeedData = Data(data: new) else { return nil }
        guard let newSeed = SendableType(data: newSeedData) else { return nil }
        guard let old = action.old else {
            self = Self(directory: directory, digest: digest, oldSeed: nil, newSeed: newSeed)
            return
        }
        guard let oldSeedData = Data(data: old) else { return nil }
        guard let oldSeed = SendableType(data: oldSeedData) else { return nil }
        self = Self(directory: directory, digest: digest, oldSeed: oldSeed, newSeed: newSeed)
    }

    func toAction() -> ActionType {
        return ActionType(key: SEED_PREFIX + directory + "/" + digest.toString(), old: oldSeed == nil ? nil : oldSeed!.toData(), new: newSeed.toData())
    }
}

