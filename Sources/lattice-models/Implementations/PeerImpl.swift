import Foundation
import Bedrock

public struct PeerImpl: Codable {
    private let rawAddress: Digest!
    private let rawOld: SendableImpl?
    private let rawNew: SendableImpl!
    
    public init(address: UInt256, old: SendableImpl?, new: SendableImpl) {
        rawAddress = address
        rawOld = old
        rawNew = new
    }
}

extension PeerImpl: ActionEncodable {
    public typealias ActionType = ActionImpl
}

extension PeerImpl: Peer {
    public typealias SendableType = SendableImpl
    public typealias Digest = UInt256
    
    public var address: UInt256! { return rawAddress }
    public var old: SendableImpl? { return rawOld }
    public var new: SendableImpl! { return rawNew }
}
