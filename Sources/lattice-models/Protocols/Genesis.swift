import Foundation
import CryptoStarterPack

public let GENESIS_PREFIX = "genesis/".toBoolArray()

public protocol Genesis: Codable, ActionEncodable {
    var directory: String { get }
    var genesisBinary: [Bool] { get }

    init(directory: String, genesisBinary: [Bool])
}

public extension Genesis {
    init?(action: ActionType) {
        let directoryBits = Array(action.key.dropLast(GENESIS_PREFIX.count))
        guard let directory = String(raw: directoryBits) else { return nil }
        if !action.old.isEmpty || action.new.isEmpty { return nil }
        self.init(directory: directory, genesisBinary: action.new)
     }

    func toAction() -> ActionType {
        return ActionType(key: GENESIS_PREFIX + directory.toBoolArray(), old: [], new: genesisBinary)
    }
}
