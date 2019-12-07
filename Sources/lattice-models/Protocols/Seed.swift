import Foundation
import Bedrock

public let SEED_PREFIX = "seed/".toBoolArray()

public protocol Seed: Codable, ActionEncodable {
    associatedtype SendableType: Sendable

    var directory: String { get }
    var oldSeeds: [SendableType]? { get }
    var newSeeds: [SendableType] { get }

    init(directory: String, oldSeeds: [SendableType]?, newSeeds: [SendableType])
}

public extension Seed {
    init?(action: ActionType) {
        let directoryBits = Array(action.key.dropLast(SEED_PREFIX.count))
        guard let directory = String(raw: directoryBits) else { return nil }
        guard let newSeedsData = Data(raw: action.new) else { return nil }
        guard let newSeeds = try? JSONDecoder().decode([SendableType].self, from: newSeedsData) else { return nil }
        if action.old.isEmpty {
            self.init(directory: directory, oldSeeds: nil, newSeeds: newSeeds)
        }
        guard let oldSeedsData = Data(raw: action.new) else { return nil }
        guard let oldSeeds = try? JSONDecoder().decode([SendableType].self, from: oldSeedsData) else { return nil }
        self.init(directory: directory, oldSeeds: oldSeeds, newSeeds: newSeeds)
    }

    func toAction() -> ActionType {
        return ActionType(key: SEED_PREFIX + directory.toBoolArray(), old: oldSeeds == nil ? [] : (try! JSONEncoder().encode(oldSeeds!)).toBoolArray(), new: (try! JSONEncoder().encode(newSeeds)).toBoolArray())
    }
}

