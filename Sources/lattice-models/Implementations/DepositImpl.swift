import Foundation
import Bedrock

public struct DepositImpl: Codable {
    private let rawDemand: DemandType!
    private let rawOldBalance: Digest!
    private let rawNewBalance: Digest!
    
    public init(demand: DemandImpl, oldBalance: UInt256, newBalance: UInt256) {
        rawDemand = demand
        rawOldBalance = oldBalance
        rawNewBalance = newBalance
    }
}

extension DepositImpl: Entry {
    public typealias ActionType = ActionImpl
    public typealias Digest = UInt256
    public var oldBalance: Digest { return rawOldBalance }
    public var newBalance: Digest { return rawNewBalance }
}

extension DepositImpl: Deposit {
    public typealias DemandType = DemandImpl
    public var demand: DemandType { return rawDemand }
}
