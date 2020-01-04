import Foundation
import CryptoStarterPack

public let GENESIS_PREFIX = "genesis/"

public protocol Genesis: Codable, ActionEncodable {
    var directory: String { get }
    var genesisData: Data { get }

    init(directory: String, genesisData: Data)
}

public extension Genesis {
    init?(action: ActionType) {
        let directory = String(action.key.dropFirst(GENESIS_PREFIX.count))
        if directory.contains("/") { return nil }
        if action.old != nil || action.new == nil { return nil }
        self.init(directory: directory, genesisData: action.new!)
     }

    func toAction() -> ActionType {
        return ActionType(key: GENESIS_PREFIX + directory, old: nil, new: genesisData)
    }
}
