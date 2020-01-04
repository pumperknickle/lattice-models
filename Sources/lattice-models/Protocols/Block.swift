import Foundation
import Bedrock
import AwesomeDictionary
import Regenerate

public protocol Block: Codable {
    associatedtype BlockBodyType: BlockBody
    
    typealias Digest = BlockBodyType.Digest
    typealias TransactionType = BlockBodyType.TransactionType
    typealias DefinitionType = BlockBodyType.DefinitionType
    
    var body: BlockBodyType? { get }
    var nextDifficulty: Digest! { get }
    var index: Digest! { get }
    var timestamp: Double! { get }
    var previous: Self? { get }
    var homestead: Digest! { get }
    var parentHomestead: Digest? { get }
    var frontier: Digest! { get }
    var genesis: Mapping<String, Self>! { get }
    var nonce: Digest! { get }
    var childrenHashes: Mapping<String, Digest>! { get }
    var children: Mapping<String, Self>! { get }
    var hash: Digest! { get }
    
    init(body: BlockBodyType?, nextDifficulty: Digest, index: Digest, timestamp: Double, previous: Self?, homestead: Digest, parentHomestead: Digest?, frontier: Digest, genesis: Mapping<String, Self>, nonce: Digest, childrenHashes: Mapping<String, Digest>, children: Mapping<String, Self>, hash: Digest)
}

public extension Block {
    func changing(body: BlockBodyType? = nil, index: Digest? = nil, timestamp: Double? = nil, homestead: Digest? = nil, frontier: Digest? = nil, genesis: Mapping<String, Self>? = nil, nonce: Digest? = nil, childrenHashes: Mapping<String, Digest>? = nil, children: Mapping<String, Self>? = nil, hash: Digest? = nil) -> Self {
        return Self(body: body ?? self.body, nextDifficulty: nextDifficulty ?? self.nextDifficulty, index: index ?? self.index, timestamp: timestamp ?? self.timestamp, previous: previous, homestead: homestead ?? self.homestead, parentHomestead: parentHomestead, frontier: frontier ?? self.frontier, genesis: genesis ?? self.genesis, nonce: nonce ?? self.nonce, childrenHashes: childrenHashes ?? self.childrenHashes, children: children ?? self.children, hash: hash ?? self.hash)
    }
    
    func verifyAllForGenesis() -> Bool {
        if !children.isEmpty() { return false }
        if !genesis.isEmpty() { return false }
        if index != Digest(0) { return false }
        if !verifyGenesisBalanceChange() { return false }
        if !verifyTransactionParents() { return false }
        if !verifyTransactions() { return false }
        guard let body = body else { return false }
        if body.transactions.contains(where: { !$0.genesisActions.isEmpty }) { return false }
        if !verifySize() { return false }
        if previous != nil { return false }
        if nextDifficulty != 0 { return false }
        return true
    }
    
    func verifyAll() -> Bool {
        if !verifyBalanceChange() { return false }
        if !verifyGenesisChildrenConflicts() { return false }
        if !verifyGenesisBlocks() { return false }
        if !verifyTransactionParents() { return false }
        if !verifyDifficulty() { return false }
        if !verifyTransactions() { return false }
        if !verifySize() { return false }
        if !verifyIndex() { return false }
        if !verifyTimestamp() { return false }
        return true
    }
    
    func verifyGenesisRelationship(to child: Self) -> Bool {
        if child.timestamp != timestamp { return false }
        guard let childParentHomestead = child.parentHomestead else { return false }
        if childParentHomestead != homestead { return false }
        guard let childDefinition = child.body?.definition else { return false }
        guard let definition = body?.definition else { return false }
        if childDefinition.period > definition.period { return false }
        if !Set(childDefinition.transactionFilters).isSuperset(of: definition.transactionFilters) { return false }
        return true
    }

    func verifyRelationship(to child: Self) -> Bool {
        guard let previous = previous else { return false }
        guard let bottomLeft = child.previous else { return false }
        if child.timestamp != timestamp { return false }
        guard let childParentHomestead = child.parentHomestead else { return false }
        if childParentHomestead != homestead { return false }
        if bottomLeft.nextDifficulty > previous.nextDifficulty { return false }
        guard let topLeft = bottomLeft.parentHomestead else { return false }
        if !verify(cycle: topLeft) { return false }
        return true
    }
    
    func verify(cycle: Digest) -> Bool {
        if homestead == cycle { return true }
        guard let previous = previous else { return false }
        return previous.verify(cycle: cycle)
    }
    
    func verifyGenesisBalanceChange() -> Bool {
        guard let body = body else { return false }
        return body.definition.premineAmount() <= body.transactions.map { $0.newBalances() }.reduce(Digest(0), +)
    }
    
    func verifyBalanceChange() -> Bool {
        guard let body = body else { return false }
        return body.transactions.map { $0.oldBalances() }.reduce(body.definition.rewardAtBlock(index: index), +) <= body.transactions.map { $0.newBalances() }.reduce(Digest(0), +)
    }
        
    func verifyGenesisChildrenConflicts() -> Bool {
        return !genesis.keys().contains(where: { children[$0] != nil })
    }
    
    func verifyGenesisBlocks() -> Bool {
        return !genesis.values().contains(where: { !$0.verifyAllForGenesis() || !verifyGenesisRelationship(to: $0) })
    }
    
    func verifyTransactionParents() -> Bool {
        guard let transactions = body?.transactions else { return false }
        return !transactions.contains(where: { $0.parentHomesteadRoot != parentHomestead })
    }
        
    func verifyDifficulty() -> Bool {
        if index == 0 { return true }
        guard let previous = previous else { return false }
        guard let definition = body?.definition else { return false }
        return definition.verifyNewDifficulty(previousDifficulty: previous.nextDifficulty, newDifficulty: nextDifficulty, blockInterval: timestamp - previous.timestamp)
    }
    
    func verifyTransactions() -> Bool {
        guard let body = body else { return false }
        return !body.transactions.contains(where: { !$0.verifyAll(filters: body.definition.transactionFilters) })
    }
    
    func verifySize() -> Bool {
        guard let body = body else { return false }
        return body.transactions.map { $0.stateDelta }.reduce(Digest(0), +) < body.definition.size
    }
    
    func verifyIndex() -> Bool {
        guard let previous = previous else { return index == Digest(0) }
        return index == previous.index.advanced(by: 1)
    }
    
    func verifyTimestamp() -> Bool {
        guard let previous = previous else { return false }
        return previous.timestamp < timestamp
    }
}
