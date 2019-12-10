import Foundation
import Bedrock

public struct DemandImpl: Codable {
    private let rawNonce: Digest!
    private let rawRecipient: Digest!
    private let rawAmount: Digest!
    
    public init(nonce: Digest, recipient: Digest, amount: Digest) {
        rawNonce = nonce
        rawRecipient = recipient
        rawAmount = amount
    }
}

extension DemandImpl: Demand {
    public typealias Digest = UInt256
    public var nonce: Digest { return rawNonce }
    public var recipient: UInt256 { return rawRecipient }
    public var amount: UInt256 { return rawAmount }
}
