import Foundation
import CryptoStarterPack

public let RECEIPTS_PREFIX = "receipt/"

public protocol Receipt: Codable, ActionEncodable {
    associatedtype DemandType: Demand
    typealias Digest = DemandType.Digest

    var sender: Digest { get }
    var demand: DemandType { get }

    init(sender: Digest, demand: DemandType)
}

public extension Receipt {
    init?(action: ActionType) {
        guard let stringKey = String(raw: action.key) else { return nil }
        if !stringKey.starts(with: RECEIPTS_PREFIX) { return nil }
        let demandString = stringKey.dropFirst(RECEIPTS_PREFIX.count)
        guard let demandData = demandString.data(using: .utf8) else { return nil }
        guard let demand = try? JSONDecoder().decode(DemandType.self, from: demandData) else { return nil }
        if !action.old.isEmpty { return nil }
        guard let sender = Digest(raw: action.new) else { return nil }
        self.init(sender: sender, demand: demand)
    }

    func toAction() -> ActionType {
        let demandString = String(bytes: try! JSONEncoder().encode(demand), encoding: .utf8)!
        return ActionType(key: (RECEIPTS_PREFIX + demandString).toBoolArray(), old: [], new: sender.toBoolArray())
    }
}
