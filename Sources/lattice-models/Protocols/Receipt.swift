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
        if !action.key.starts(with: RECEIPTS_PREFIX) { return nil }
        let demandString = action.key.dropFirst(RECEIPTS_PREFIX.count)
        guard let demandData = demandString.data(using: .utf8) else { return nil }
        guard let demand = DemandType(data: demandData) else { return nil }
        if action.old != nil { return nil }
        guard let new = action.new else { return nil }
        guard let sender = Digest(data: new) else { return nil }
        self.init(sender: sender, demand: demand)
    }

    func toAction() -> ActionType {
        let demandString = String(bytes: demand.toData(), encoding: .utf8)!
        return ActionType(key: RECEIPTS_PREFIX + demandString, old: nil, new: sender.toData())
    }
}
