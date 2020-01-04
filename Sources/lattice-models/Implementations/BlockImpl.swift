import Foundation
import AwesomeDictionary

public struct BlockImpl: Codable {
    private let rawBody: BlockBodyType?
    private let rawNextDifficulty: Digest!
    private let rawIndex: Digest!
    private let rawTimestamp: Double!
    private let rawPrevious: [Self]!
    private let rawHomestead: Digest!
    private let rawParentHomestead: Digest?
    private let rawFrontier: Digest!
    private let rawGenesis: Mapping<String, Self>!
    private let rawNonce: Digest!
    private let rawChildrenHashes: Mapping<String, Digest>!
    private let rawChildren: Mapping<String, Self>!
    private let rawHash: Digest!
    
    public init(body: BlockBodyType?, nextDifficulty: Digest, index: Digest, timestamp: Double, previous: Self?, homestead: Digest, parentHomestead: Digest?, frontier: Digest, genesis: Mapping<String, Self>, nonce: Digest, childrenHashes: Mapping<String, Digest>, children: Mapping<String, Self>, hash: Digest) {
        rawBody = body
        rawNextDifficulty = nextDifficulty
        rawIndex = index
        rawTimestamp = timestamp
        rawPrevious = previous != nil ? [previous!] : []
        rawHomestead = homestead
        rawParentHomestead = parentHomestead
        rawFrontier = frontier
        rawGenesis = genesis
        rawNonce = nonce
        rawChildrenHashes = childrenHashes
        rawChildren = children
        rawHash = hash
    }
}

extension BlockImpl: Block {
    public typealias BlockBodyType = BlockBodyImpl

    public var body: BlockBodyType? { return rawBody }
    public var nextDifficulty: Digest! { return rawNextDifficulty }
    public var index: Digest! { return rawIndex }
    public var timestamp: Double! { return rawTimestamp }
    public var previous: Self? { return rawPrevious.first }
    public var homestead: Digest! { return rawHomestead }
    public var parentHomestead: Digest? { return rawParentHomestead }
    public var frontier: Digest! { return rawFrontier }
    public var genesis: Mapping<String, Self>! { return rawGenesis }
    public var nonce: Digest! { return rawNonce }
    public var childrenHashes: Mapping<String, Digest>! { return rawChildrenHashes }
    public var children: Mapping<String, Self>! { return rawChildren }
    public var hash: Digest! { return rawHash }
}
