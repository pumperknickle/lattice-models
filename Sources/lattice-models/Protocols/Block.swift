import Foundation
import Bedrock
import AwesomeDictionary
import Regenerate

public protocol Block: Codable {
    associatedtype Digest
    associatedtype TransactionType: Transaction where TransactionType.Digest == Digest
    associatedtype DefinitionType: Definition where DefinitionType.Digest == Digest
    
    var transactions: [TransactionType]! { get }
    var definition: DefinitionType? { get }
    var nextDifficulty: Digest! { get }
    var index: Digest! { get }
    var timestamp: Double! { get }
    var previous: Self? { get }
    var homestead: Digest! { get }
    var parentHomestead: Digest? { get }
    var frontier: Digest! { get }
    var genesis: Mapping<String, Self>! { get }
    var nonce: Digest! { get }
    var proofOfWork: Digest? { get }
    var childrenHashes: Mapping<String, Digest>! { get }
    var children: Mapping<String, Self>! { get }
    var proofOfWorkExceedsDifficulty: Bool! { get }
    var hash: Digest! { get }
    
    init(transactions: [TransactionType], definition: DefinitionType?, nextDifficulty: Digest, index: Digest, previous: Self?, homestead: Digest, parentHomestead: Digest?, frontier: Digest, genesis: Mapping<String, Self>, nonce: Digest, proofOfWork: Digest?, childrenHashes: Mapping<String, Digest>, children: Mapping<String, Self>, proofOfWorkExceedsDifficulty: Bool, hash: Digest)
}

public extension Block {
    func insert(child: Self, directory: [String]) -> Self? {
        guard let firstLeg = directory.first else { return nil }
        guard let childBlock = children[firstLeg] else {
            if !verifyRelationship(to: child) { return nil }
            if child.proofOfWorkExceedsDifficulty && !child.verifyAll() { return nil }
            if !child.children.isEmpty() { return nil }
            return changing(childrenHashes: childrenHashes.setting(key: firstLeg, value: child.hash), children: children.setting(key: firstLeg, value: child))
        }
        guard let insertedChildBlock = childBlock.insert(child: child, directory: Array(directory.dropFirst())) else { return nil }
        return changing(children: children.setting(key: firstLeg, value: insertedChildBlock))
    }
    
    func changing(transactions: [TransactionType]? = nil, nextDifficulty: Digest? = nil, index: Digest? = nil, timestamp: Double? = nil, homestead: Digest? = nil, frontier: Digest? = nil, genesis: Mapping<String, Self>? = nil, nonce: Digest? = nil, childrenHashes: Mapping<String, Digest>? = nil, children: Mapping<String, Self>? = nil, proofOfWorkExceedsDifficulty: Bool? = nil, hash: Digest? = nil) -> Self {
        return Self(transactions: transactions ?? self.transactions, definition: definition, nextDifficulty: nextDifficulty ?? self.nextDifficulty, index: index ?? self.index, previous: previous, homestead: homestead ?? self.homestead, parentHomestead: parentHomestead, frontier: frontier ?? self.frontier, genesis: genesis ?? self.genesis, nonce: nonce ?? self.nonce, proofOfWork: proofOfWork, childrenHashes: childrenHashes ?? self.childrenHashes, children: children ?? self.children, proofOfWorkExceedsDifficulty: proofOfWorkExceedsDifficulty ?? self.proofOfWorkExceedsDifficulty, hash: hash ?? self.hash)
    }
    
    func verifyAllForGenesis() -> Bool {
        if !children.isEmpty() { return false }
        if !genesis.isEmpty() { return false }
        if index != Digest(0) { return false }
        if !verifyGenesisBalanceChange() { return false }
        if !verifyTransactionParents() { return false }
        if !verifyTransactions() { return false }
        if transactions.contains(where: { !$0.genesisActions.isEmpty }) { return false }
        if !verifySize() { return false }
        if previous != nil { return false }
        return true
    }
    
    func verifyAll() -> Bool {
        if !verifyBalanceChange() { return false }
        if !verifyGenesisChildrenConflicts() { return false }
        if !verifyGenesisBlocks() { return false }
        if !verifyTransactionParents() { return false }
        if !verifyDifficulty() { return false }
        if !verifyProofOfWork() { return false }
        if !verifyTransactions() { return false }
        if !verifySize() { return false }
        if !verifyIndex() { return false }
        if !verifyTimstamp() { return false }
        return true
    }
    
    func verifyGenesisRelationship(to child: Self) -> Bool {
        if child.timestamp != timestamp { return false }
        guard let childParentHomestead = child.parentHomestead else { return false }
        if childParentHomestead != homestead { return false }
        if child.proofOfWork != proofOfWork { return false }
        guard let childDefinition = child.definition else { return false }
        guard let definition = definition else { return false }
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
        if child.proofOfWork != proofOfWork { return false }
        if bottomLeft.nextDifficulty > previous.nextDifficulty { return false }
        guard let topLeft = bottomLeft.parentHomestead else { return false }
        if !verify(cycle: topLeft) { return false }
        if proofOfWorkExceedsDifficulty && !child.proofOfWorkExceedsDifficulty { return false }
        return true
    }
    
    func verify(cycle: Digest) -> Bool {
        if homestead == cycle { return true }
        guard let previous = previous else { return false }
        return previous.verify(cycle: cycle)
    }
    
    func verifyGenesisBalanceChange() -> Bool {
        guard let definition = definition else { return false }
        return definition.premineAmount() <= transactions.map { $0.newBalances() }.reduce(Digest(0), +)
    }
    
    func verifyBalanceChange() -> Bool {
        guard let definition = definition else { return false }
        return transactions.map { $0.oldBalances() }.reduce(definition.rewardAtBlock(index: index), +) <= transactions.map { $0.newBalances() }.reduce(Digest(0), +)
    }
        
    func verifyGenesisChildrenConflicts() -> Bool {
        return !genesis.keys().contains(where: { children[$0] != nil })
    }
    
    func verifyGenesisBlocks() -> Bool {
        return !genesis.values().contains(where: { !$0.verifyAllForGenesis() || !verifyGenesisRelationship(to: $0) })
    }
    
    func verifyTransactionParents() -> Bool {
        guard let transactions = transactions else { return false }
        return !transactions.contains(where: { $0.parentHomesteadRoot != parentHomestead })
    }
        
    func verifyDifficulty() -> Bool {
        if index == 0 { return true }
        guard let previous = previous else { return false }
        guard let definition = definition else { return false }
        return definition.verifyNewDifficulty(previousDifficulty: previous.nextDifficulty, newDifficulty: nextDifficulty, blockInterval: timestamp - previous.timestamp)
    }
    
    func verifyProofOfWork() -> Bool {
        guard let previous = previous else { return false }
        guard let proofOfWork = proofOfWork else { return false }
        return proofOfWork < previous.nextDifficulty
    }
    
    func verifyTransactions() -> Bool {
        guard let definition = definition else { return false }
        return !transactions.contains(where: { !$0.verifyAll(filters: definition.transactionFilters) })
    }
    
    func verifySize() -> Bool {
        guard let definition = definition else { return false }
        return transactions.map { $0.stateDelta }.reduce(Digest(0), +) < definition.size
    }
    
    func verifyIndex() -> Bool {
        guard let previous = previous else { return index == Digest(0) }
        return index == previous.index.advanced(by: 1)
    }
    
    func verifyTimstamp() -> Bool {
        guard let previous = previous else { return false }
        return previous.timestamp < timestamp
    }
}
