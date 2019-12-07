import Foundation
import Bedrock

public struct AccountImpl: Codable {
    private let rawAddress: Digest!
    private let rawOldBalance: Digest!
    private let rawNewBalance: Digest!
    
    public init(address: Digest, oldBalance: Digest, newBalance: Digest) {
        rawAddress = address
        rawOldBalance = oldBalance
        rawNewBalance = newBalance
    }
}

extension AccountImpl: Entry {
    public var oldBalance: Digest { return rawOldBalance }
    public var newBalance: Digest { return rawNewBalance }
    
    public typealias Digest = UInt256
    public typealias ActionType = ActionImpl
}

extension AccountImpl: Account {
    public var address: UInt256 { return rawAddress }
}
