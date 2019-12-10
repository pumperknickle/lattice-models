import Foundation
import Bedrock

public let PEER_PREFIX = "peer/"

public protocol Peer: Codable, ActionEncodable {
    associatedtype SendableType: Sendable
    associatedtype Digest: FixedWidthInteger, Stringable

    var address: Digest! { get }
    var old: SendableType? { get }
    var new: SendableType! { get }

    init(address: Digest, old: SendableType?, new: SendableType)
}

public extension Peer {
    init?(action: ActionType) {
        guard let stringKey = String(raw: action.key) else { return nil }
        let addressString = String(stringKey.dropFirst(PEER_PREFIX.count))
        guard let address = Digest(stringValue: addressString) else { return nil }
        guard let new = SendableType(raw: action.new) else { return nil }
        if action.old.isEmpty {
            self = Self(address: address, old: nil, new: new)
            return
        }
        guard let old = SendableType(raw: action.old) else { return nil }
        self.init(address: address, old: old, new: new)
    }

    func toAction() -> ActionType {
        return ActionType(key: (PEER_PREFIX + address.toString()).toBoolArray(), old: old == nil ? [] : old!.toBoolArray(), new: new.toBoolArray())
    }
}
