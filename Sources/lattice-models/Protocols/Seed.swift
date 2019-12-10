import Foundation
import Bedrock

public let SEED_PREFIX = "seed/"

public protocol Seed: Codable, ActionEncodable {
    associatedtype SendableType: Sendable

    var directory: String { get }
    var oldSeeds: [SendableType]? { get }
    var newSeeds: [SendableType] { get }

    init(directory: String, oldSeeds: [SendableType]?, newSeeds: [SendableType])
}

public extension Seed {
    init?(action: ActionType) {
        guard let stringKey = String(raw: action.key) else { return nil }
        let directory = String(stringKey.dropFirst(SEED_PREFIX.count))
        guard let newSeedsData = Data(raw: action.new) else { return nil }
        guard let newSeeds = try? JSONDecoder().decode([SendableType].self, from: newSeedsData) else { return nil }
        if action.old.isEmpty {
            self = Self(directory: directory, oldSeeds: nil, newSeeds: newSeeds)
            return
        }
        guard let oldSeedsData = Data(raw: action.new) else { return nil }
        guard let oldSeeds = try? JSONDecoder().decode([SendableType].self, from: oldSeedsData) else { return nil }
        self = Self(directory: directory, oldSeeds: oldSeeds, newSeeds: newSeeds)
    }

    func toAction() -> ActionType {
        return ActionType(key: (SEED_PREFIX + directory).toBoolArray(), old: oldSeeds == nil ? [] : (try! JSONEncoder().encode(oldSeeds!)).toBoolArray(), new: (try! JSONEncoder().encode(newSeeds)).toBoolArray())
    }
}

