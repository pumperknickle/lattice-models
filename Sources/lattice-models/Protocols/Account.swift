import Foundation
import CryptoStarterPack

public let ACCOUNT_PREFIX = "account/"

public protocol Account: Entry {
    var address: Digest { get }

    init(address: Digest, oldBalance: Digest, newBalance: Digest)
}

public extension Account {
    init?(action: ActionType) {
        guard let stringKey = String(raw: action.key) else { return nil }
        let addressString = String(stringKey.dropFirst(ACCOUNT_PREFIX.count))
        guard let address = Digest(stringValue: addressString) else { return nil }
        guard let oldBalance = Digest(raw: action.old) else { return nil }
        guard let newBalance = Digest(raw: action.new) else { return nil }
        self.init(address: address, oldBalance: oldBalance, newBalance: newBalance)
    }

    func toAction() -> ActionType {
        return ActionType(key: (ACCOUNT_PREFIX + address.toString()).toBoolArray(), old: oldBalance == Digest(0) ? [] : oldBalance.toBoolArray(), new: newBalance == Digest(0) ? [] : newBalance.toBoolArray())
    }
}
