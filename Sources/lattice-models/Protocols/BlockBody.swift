import Foundation

public protocol BlockBody: Codable {
    associatedtype Digest
    associatedtype TransactionType: Transaction where TransactionType.Digest == Digest
    associatedtype DefinitionType: Definition where DefinitionType.Digest == Digest
    
    var transactions: [TransactionType]! { get }
    var definition: DefinitionType! { get }
    
    init(transactions: [TransactionType], definition: DefinitionType)
}
