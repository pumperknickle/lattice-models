import Foundation
import Bedrock
import Regenerate

public struct BlockArtifactImpl: Codable {
    private let rawTransactionsRoot: TransactionArrayAddress!
    private let rawDefinitionRoot: DefinitionAddress!
    private let rawNextDifficulty: Digest!
    private let rawIndex: Digest!
    private let rawTimestamp: Double!
    private let rawPreviousRoot: [BlockAddress]!
    private let rawHomestead: Digest!
    private let rawParentIndex: Digest?
    private let rawParentHomestead: Digest?
    private let rawFrontier: Digest!
    private let rawNonce: Digest!
    private let rawChildren: BlockDictionaryAddress!
    
    public init(transactionsRoot: TransactionArrayAddress, definitionRoot: DefinitionAddress, nextDifficulty: Digest, index: Digest, timestamp: Double, previousRoot: BlockAddress?, homestead: Digest, parentIndex: Digest?, parentHomesteead: Digest?, frontier: Digest, nonce: Digest, children: BlockDictionaryAddress) {
        rawTransactionsRoot = transactionsRoot
        rawDefinitionRoot = definitionRoot
        rawNextDifficulty = nextDifficulty
        rawIndex = index
        rawTimestamp = timestamp
        rawPreviousRoot = previousRoot != nil ? [previousRoot!] : []
        rawHomestead = homestead
        rawParentIndex = parentIndex
        rawParentHomestead = parentHomesteead
        rawFrontier = frontier
        rawNonce = nonce
        rawChildren = children
    }
}

extension BlockArtifactImpl: BlockArtifact {
    public typealias Digest = UInt256
    public typealias BlockType = BlockImpl
    public typealias TransactionArtifactType = TransactionArtifactImpl
    public typealias TransactionAddress = Address<TransactionArtifactType>
    public typealias TransactionArray = Array256<TransactionAddress>
    public typealias TransactionArrayAddress = Address<TransactionArray>
    public typealias DefinitionArtifactType = DefinitionArtifactImpl
    public typealias DefinitionAddress = Address<DefinitionArtifactType>
    public typealias BlockAddress = Address<Self>
    public typealias BlockDictionary = Dictionary256<String, BlockAddress>
    public typealias BlockDictionaryAddress = Address<BlockDictionary>
    
    public var transactionsRoot: TransactionArrayAddress! { return rawTransactionsRoot }
    public var definitionRoot: DefinitionAddress! { return rawDefinitionRoot }
    public var nextDifficulty: Digest! { return rawNextDifficulty }
    public var index: Digest! { return rawIndex }
    public var timestamp: Double! { return rawTimestamp }
    public var previousRoot: BlockAddress? { return rawPreviousRoot.first }
    public var homestead: Digest! { return rawHomestead }
    public var parentIndex: Digest? { return rawParentIndex }
    public var parentHomestead: Digest? { return rawParentHomestead }
    public var frontier: Digest! { return rawFrontier }
    public var nonce: Digest! { return rawNonce }
    public var children: BlockDictionaryAddress! { return rawChildren }
}
