import Foundation
import Bedrock

public let DEPOSIT_PREFIX = "deposit/".toBoolArray()

public protocol Deposit: Entry {
    associatedtype DemandType: Demand where DemandType.Digest == Digest

    var demand: DemandType { get }

    init(demand: DemandType, oldBalance: Digest, newBalance: Digest)
}

public extension Deposit {
    init?(action: ActionType) {
        if !action.key.starts(with: DEPOSIT_PREFIX) { return nil }
        let demandBits = Array(action.key.dropFirst(DEPOSIT_PREFIX.count))
        guard let demand = DemandType(raw: demandBits) else { return nil }
        if action.old.isEmpty {
            if action.new.isEmpty { return nil }
            let oldBalance = Digest(0)
            guard let newBalance = Digest(raw: action.new) else { return nil }
            self.init(demand: demand, oldBalance: oldBalance, newBalance: newBalance)
        }
        if action.new.isEmpty {
            if action.old.isEmpty { return nil }
            let newBalance = Digest(0)
            guard let oldBalance = Digest(raw: action.old) else { return nil }
            self.init(demand: demand, oldBalance: oldBalance, newBalance: newBalance)
        }
        guard let oldBalance = Digest(raw: action.old) else { return nil }
        guard let newBalance = Digest(raw: action.new) else { return nil }
        self.init(demand: demand, oldBalance: oldBalance, newBalance: newBalance)
    }

    func toAction() -> ActionType {
        return ActionType(key: DEPOSIT_PREFIX + demand.toBoolArray(), old: oldBalance == Digest(0) ? [] : oldBalance.toBoolArray(), new: newBalance == Digest(0) ? [] : newBalance.toBoolArray())
    }
}
