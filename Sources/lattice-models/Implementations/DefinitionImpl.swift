import Foundation
import Bedrock

public struct DefinitionImpl: Codable {
    private let rawSize: Digest!
    private let rawPremine: Digest!
    private let rawPeriod: Double!
    private let rawInitialRewardExponent: Int!
    private let rawTransactionFilters: [String]!
    public init(size: UInt256, premine: UInt256, period: Double, initialRewardExponent: Int, transactionFilters: [String]) {
        rawSize = size
        rawPremine = premine
        rawPeriod = period
        rawInitialRewardExponent = initialRewardExponent
        rawTransactionFilters = transactionFilters
    }
}

extension DefinitionImpl: Definition {
    public typealias Digest = UInt256
    public var size: UInt256! { return rawSize }
    public var premine: UInt256! { return rawPremine }
    public var period: Double! { return rawPeriod }
    public var initialRewardExponent: Int! { return rawInitialRewardExponent }
    public var transactionFilters: [String]! { return rawTransactionFilters }
}
