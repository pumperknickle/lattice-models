import Foundation
import CryptoStarterPack

public let ACCOUNT_PREFIX = "account/"

public protocol Account: Entry {
    var address: Digest { get }

    init(address: Digest, oldBalance: Digest, newBalance: Digest)
}

public extension Account {
    init?(action: ActionType) {
        let addressString = String(action.key.dropFirst(ACCOUNT_PREFIX.count))
        guard let address = Digest(stringValue: addressString) else { return nil }
        guard let oldBalance = action.old == nil ? Digest(0) : Digest(data: action.old!) else { return nil }
        guard let newBalance = action.new == nil ? Digest(0) : Digest(data: action.new!) else { return nil }
        self.init(address: address, oldBalance: oldBalance, newBalance: newBalance)
    }

    func toAction() -> ActionType {
        return ActionType(key: ACCOUNT_PREFIX + address.toString(), old: oldBalance == Digest(0) ? nil : oldBalance.toData(), new: newBalance == Digest(0) ? nil : newBalance.toData())
    }
}
