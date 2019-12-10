import Foundation
import CryptoStarterPack

public let GENESIS_PREFIX = "genesis/"

public protocol Genesis: Codable, ActionEncodable {
    var directory: String { get }
    var genesisBinary: [Bool] { get }

    init(directory: String, genesisBinary: [Bool])
}

public extension Genesis {
    init?(action: ActionType) {
        guard let stringKey = String(raw: action.key) else { return nil }
        let directory = String(stringKey.dropFirst(GENESIS_PREFIX.count))
        if !action.old.isEmpty || action.new.isEmpty { return nil }
        self.init(directory: directory, genesisBinary: action.new)
     }

    func toAction() -> ActionType {
        return ActionType(key: (GENESIS_PREFIX + directory).toBoolArray(), old: [], new: genesisBinary)
    }
}
