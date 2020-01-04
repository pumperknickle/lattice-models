import Foundation
import Bedrock

public let DEPOSIT_PREFIX = "deposit/"

public protocol Deposit: Entry {
    associatedtype DemandType: Demand where DemandType.Digest == Digest

    var demand: DemandType { get }

    init(demand: DemandType, oldBalance: Digest, newBalance: Digest)
}

public extension Deposit {
    init?(action: ActionType) {
        if !action.key.starts(with: DEPOSIT_PREFIX) { return nil }
        let demandString = action.key.dropFirst(DEPOSIT_PREFIX.count)
        guard let demandData = demandString.data(using: .utf8) else { return nil }
        guard let demand = DemandType(data: demandData) else { return nil }
        guard let old = action.old else {
            guard let new = action.new else { return nil }
            let oldBalance = Digest(0)
            guard let newBalance = Digest(data: new) else { return nil }
            self.init(demand: demand, oldBalance: oldBalance, newBalance: newBalance)
            return
        }
        guard let new = action.new else {
            let newBalance = Digest(0)
            guard let oldBalance = Digest(data: old) else { return nil }
            self.init(demand: demand, oldBalance: oldBalance, newBalance: newBalance)
            return
        }
        guard let oldBalance = Digest(data: old) else { return nil }
        guard let newBalance = Digest(data: new) else { return nil }
        self.init(demand: demand, oldBalance: oldBalance, newBalance: newBalance)
    }

    func toAction() -> ActionType {
        let demandString = String(bytes: demand.toData(), encoding: .utf8)!
        return ActionType(key: DEPOSIT_PREFIX + demandString, old: oldBalance == Digest(0) ? nil : oldBalance.toData(), new: newBalance == Digest(0) ? nil : newBalance.toData())
    }
}
