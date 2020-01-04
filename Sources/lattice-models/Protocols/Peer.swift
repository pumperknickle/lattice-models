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
        let addressString = String(action.key.dropFirst(PEER_PREFIX.count))
        guard let address = Digest(stringValue: addressString) else { return nil }
        guard let new = action.new else { return nil }
        guard let newSendable = SendableType(data: new) else { return nil }
        guard let old = action.old else {
            self = Self(address: address, old: nil, new: newSendable)
            return
        }
        guard let oldSendable = SendableType(data: old) else { return nil }
        self.init(address: address, old: oldSendable, new: newSendable)
    }

    func toAction() -> ActionType {
        return ActionType(key: PEER_PREFIX + address.toString(), old: old == nil ? nil : old!.toData(), new: new.toData())
    }
}
