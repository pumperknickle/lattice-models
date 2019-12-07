import Foundation
import CryptoStarterPack

public let RECEIPTS_PREFIX = "receipt/".toBoolArray()

public protocol Receipt: Codable, ActionEncodable {
    associatedtype DemandType: Demand
    typealias Digest = DemandType.Digest

    var sender: Digest { get }
    var demand: DemandType { get }

    init(sender: Digest, demand: DemandType)
}

public extension Receipt {
    init?(action: ActionType) {
        let demandBits = Array(action.key.dropLast(RECEIPTS_PREFIX.count))
        guard let demand = DemandType(raw: demandBits) else { return nil }
        if !action.old.isEmpty { return nil }
        guard let sender = Digest(raw: action.new) else { return nil }
        self.init(sender: sender, demand: demand)
    }

    func toAction() -> ActionType {
        return ActionType(key: RECEIPTS_PREFIX + demand.toBoolArray(), old: [], new: sender.toBoolArray())
    }
}
