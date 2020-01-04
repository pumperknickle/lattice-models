import Foundation
import Bedrock

public struct BlockBodyImpl: Codable {
    private let rawTransactions: [TransactionType]!
    private let rawDefinition: DefinitionType!
    
    public init(transactions: [TransactionType], definition: DefinitionType) {
        rawTransactions = transactions
        rawDefinition = definition
    }
}

extension BlockBodyImpl: BlockBody {
    public typealias Digest = UInt256
    public typealias TransactionType = TransactionImpl
    public typealias DefinitionType = DefinitionImpl
    
    public var transactions: [TransactionType]! { return rawTransactions }
    public var definition: DefinitionType! { return rawDefinition }
}

