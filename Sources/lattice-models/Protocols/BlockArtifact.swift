import Foundation
import Bedrock
import JavaScriptCore
import Regenerate
import CryptoStarterPack
import AwesomeTrie
import AwesomeDictionary

public protocol BlockArtifact: RGArtifact {
    associatedtype Digest
    
    associatedtype BlockType: Block where BlockType.Digest == Digest, BlockType.TransactionType == TransactionType, BlockType.DefinitionType == DefinitionType
    
    associatedtype TransactionArtifactType: TransactionArtifact where TransactionArtifactType.Digest == Digest
    associatedtype TransactionAddress where TransactionAddress.Artifact == TransactionArtifactType, TransactionAddress.Digest == Digest, TransactionAddress.CryptoDelegateType == CryptoDelegateType
    associatedtype TransactionArray: RGArray where TransactionArray.Element == TransactionAddress
    associatedtype TransactionArrayAddress: Addressable where TransactionArrayAddress.Artifact == TransactionArray, TransactionArrayAddress.Digest == Digest, TransactionArrayAddress.CryptoDelegateType == CryptoDelegateType

    associatedtype DefinitionArtifactType: DefinitionArtitact where DefinitionArtifactType.Digest == Digest
    associatedtype DefinitionAddress: Addressable where DefinitionAddress.Artifact == DefinitionArtifactType, DefinitionAddress.Digest == Digest, DefinitionAddress.CryptoDelegateType == CryptoDelegateType
    
    associatedtype BlockAddress where BlockAddress.Artifact == Self, BlockAddress.Digest == Digest, BlockAddress.CryptoDelegateType == CryptoDelegateType
    associatedtype BlockDictionary: RGDictionary where BlockDictionary.Key == String, BlockDictionary.Value == BlockAddress
    associatedtype BlockDictionaryAddress: Addressable where BlockDictionaryAddress.Artifact == BlockDictionary, BlockDictionaryAddress.Digest == Digest, BlockDictionaryAddress.CryptoDelegateType == CryptoDelegateType
    
    typealias BlockBodyType = BlockType.BlockBodyType
    typealias DataScalar = TransactionArtifactType.DataScalar
    typealias DataAddress = TransactionArtifactType.DataAddress
    typealias State = TransactionArtifactType.State
    typealias StateAddress = TransactionArtifactType.StateAddress
    typealias StateObject = TransactionArtifactType.StateObject
    typealias TransactionType = TransactionArtifactType.TransactionType
    typealias DefinitionType = DefinitionArtifactType.DefinitionType
    typealias CryptoDelegateType = TransactionArtifactType.CryptoDelegateType
    typealias AsymmetricDelegateType = TransactionArtifactType.AsymmetricDelegateType

    var transactionsRoot: TransactionArrayAddress! { get }
    var definitionRoot: DefinitionAddress! { get }
    var nextDifficulty: Digest! { get }
    var index: Digest! { get }
    var timestamp: Double! { get }
    var previousRoot: BlockAddress? { get }
    var homestead: Digest! { get }
    // index where parent block frontier == homestead
    var parentIndex: Digest? { get }
    var parentHomestead: Digest? { get }
    var frontier: Digest! { get }
    var nonce: Digest! { get }
    var children: BlockDictionaryAddress! { get }
    
    func toBlock() -> BlockType?
    func hash() -> Digest?
    
    init(transactionsRoot: TransactionArrayAddress, definitionRoot: DefinitionAddress, nextDifficulty: Digest, index: Digest, timestamp: Double, previousRoot: BlockAddress?, homestead: Digest, parentIndex: Digest?, parentHomesteead: Digest?, frontier: Digest, nonce: Digest, children: BlockDictionaryAddress)
}

public extension BlockArtifact {
    init?(transactionArtifacts: [TransactionArtifactType], definitionArtifact: DefinitionArtifactType, nextDifficulty: Digest, index: Digest, timestamp: Double, previousBlock: Self?, homestead: Digest, parent: (parentIndex: Digest, parentHomestead: Digest)?, nonce: Digest, children: [String: Self]) {
        if let previousBlock = previousBlock {
            guard let childDictionary = BlockDictionary(da: children) else { return nil }
            guard let childAddress = BlockDictionaryAddress(artifact: childDictionary, complete: true) else { return nil }
            guard let previousAddress = BlockAddress(artifact: previousBlock, complete: true) else { return nil }
            guard let transactionsRoot = Self.convert(transactionArtifacts: transactionArtifacts) else { return nil }
            guard let definitionRoot = DefinitionAddress(artifact: definitionArtifact, complete: true) else { return nil }
            guard let frontierState = Self.getFrontierDigest(homestead: homestead, transactionsRoot: transactionsRoot) else { return nil }
            self = Self(transactionsRoot: transactionsRoot, definitionRoot: definitionRoot, nextDifficulty: nextDifficulty, index: index, timestamp: timestamp, previousRoot: previousAddress, homestead: homestead, parentIndex: parent?.parentIndex, parentHomesteead: parent?.parentHomestead, frontier: frontierState, nonce: nonce, children: childAddress)
        }
        else {
            if index != Digest(0) { return nil }
            guard let genesis = Self.createGenesis(transactionArtifacts: transactionArtifacts, definitionArtifact: definitionArtifact, nextDifficulty: nextDifficulty, timestamp: timestamp, parentIndex: parent?.parentIndex, parentHomestead: parent?.parentHomestead, nonce: nonce) else { return nil }
            self = genesis
        }        
    }
    
    func changing(transactionArtifacts: [TransactionArtifactType]) -> Self? {
        guard let transactionsRoot = Self.convert(transactionArtifacts: transactionArtifacts) else { return nil }
        return changing(transactionsRoot: transactionsRoot)
    }
    
    func changing(transactionsRoot: TransactionArrayAddress? = nil, definitionRoot: DefinitionAddress? = nil, nextDifficulty: Digest? = nil, index: Digest? = nil, timestamp: Double? = nil, homestead: Digest? = nil, frontier: Digest? = nil, nonce: Digest? = nil, children: BlockDictionaryAddress? = nil) -> Self {
        return Self(transactionsRoot: transactionsRoot ?? self.transactionsRoot, definitionRoot: definitionRoot ?? self.definitionRoot, nextDifficulty: nextDifficulty ?? self.nextDifficulty, index: index ?? self.index, timestamp: timestamp ?? self.timestamp, previousRoot: previousRoot, homestead: homestead ?? self.homestead, parentIndex: parentIndex, parentHomesteead: parentHomestead, frontier: frontier ?? self.frontier, nonce: nonce ?? self.nonce, children: children ?? self.children)
    }
    
    func changing(previousRoot: BlockAddress?) -> Self {
        return Self(transactionsRoot: transactionsRoot, definitionRoot: definitionRoot, nextDifficulty: nextDifficulty, index: index, timestamp: timestamp, previousRoot: previousRoot, homestead: homestead, parentIndex: parentIndex, parentHomesteead: parentHomestead, frontier: frontier, nonce: nonce, children: children)
    }
    
    static func transactionsProperty() -> String {
        return "transactions"
    }
    
    static func definitionsProperty() -> String {
        return "definitions"
    }
    
    static func previousProperty() -> String {
        return "previous"
    }
    
    static func childrenProperty() -> String {
        return "children"
    }
    
    static func properties() -> [String] {
        return [transactionsProperty(), definitionsProperty(), previousProperty(), childrenProperty()]
    }
    
    func set(property: String, to child: CryptoBindable) -> Self? {
        switch property {
        case Self.transactionsProperty():
            guard let newChild = child as? TransactionArrayAddress else { return nil }
            return changing(transactionsRoot: newChild)
        case Self.definitionsProperty():
            guard let newChild = child as? DefinitionAddress else { return nil }
            return changing(definitionRoot: newChild)
        case Self.previousProperty():
            guard let newChild = child as? BlockAddress else { return nil }
            return changing(previousRoot: newChild)
        case Self.childrenProperty():
            guard let newChild = child as? BlockDictionaryAddress else { return nil }
            return changing(children: newChild)
        default:
            return nil
        }
    }
    
    func get(property: String) -> CryptoBindable? {
        switch property {
        case Self.transactionsProperty():
            return transactionsRoot
        case Self.definitionsProperty():
            return definitionRoot
        case Self.previousProperty():
            return previousRoot
        case Self.childrenProperty():
            return children
        default:
            return nil
        }
    }
    
    static func emptyRoot() -> Digest? {
        guard let emptyState = State(da: [:]) else { return nil }
        return StateAddress(artifact: emptyState, complete: true)?.digest
    }
    
    static func emptyChildRoot() -> BlockDictionaryAddress? {
        guard let emptyChildren = BlockDictionary(da: [:]) else { return nil }
        return BlockDictionaryAddress(artifact: emptyChildren, complete: true)
    }
    
    static func createGenesis(transactionArtifacts: [TransactionArtifactType], definitionArtifact: DefinitionArtifactType, nextDifficulty: Digest, timestamp: Double, parentIndex: Digest?, parentHomestead: Digest?, nonce: Digest) -> Self? {
        guard let transactionsRoot = Self.convert(transactionArtifacts: transactionArtifacts) else { return nil }
        guard let definitionRoot = DefinitionAddress(artifact: definitionArtifact, complete: true) else { return nil }
        guard let emptyRoot = Self.emptyRoot() else { return nil }
        guard let frontierState = Self.getFrontierDigest(homestead: emptyRoot, transactionsRoot: transactionsRoot) else { return nil }
        guard let emptyChildRoot = Self.emptyChildRoot() else { return nil }
        return Self(transactionsRoot: transactionsRoot, definitionRoot: definitionRoot, nextDifficulty: nextDifficulty, index: Digest(0), timestamp: timestamp, previousRoot: nil, homestead: emptyRoot, parentIndex: parentIndex, parentHomesteead: parentHomestead, frontier: frontierState, nonce: nonce, children: emptyChildRoot)
    }
    
    func hash() -> Digest? {
        return BlockAddress(artifact: self, complete: true)?.digest
    }
    
    func convertChildBlocks() -> Mapping<String, BlockType>? {
        guard let childDictionary = children.artifact?.children else { return nil }
        return childDictionary.elements().reduce(Mapping<String, BlockType>()) { (result, entry) -> Mapping<String, BlockType>? in
            guard let result = result else { return nil }
            guard let rawBlock = entry.1.artifact else { return nil }
            guard let block = rawBlock.toBlock() else { return nil }
            return result.setting(key: entry.0, value: block)
        }
    }
    
    func toBlock() -> BlockType? {
        guard let previousRoot = previousRoot else { return nil }
        guard let previous = previousRoot.artifact?.backwardsChain(hash: previousRoot.digest) else { return nil }
        guard let hash = hash() else { return nil }
        guard let childBlocks = convertChildBlocks() else { return nil }
        let childHashes = childBlocks.elements().reduce(Mapping<String, Digest>()) { (result, entry) -> Mapping<String, Digest>? in
            guard let result = result else { return nil }
            guard let childHash = entry.1.hash else { return nil }
            return result.setting(key: entry.0, value: childHash)
        }
        guard let finalChildHashes = childHashes else { return nil }
        if !definitionRoot.complete || !transactionsRoot.complete {
            return BlockType(body: nil, definitionHash: definitionRoot.digest, nextDifficulty: nextDifficulty, index: index, timestamp: timestamp, previous: previous, homestead: homestead, parentHomestead: parentHomestead, frontier: frontier, genesis: Mapping<String, BlockType>(), nonce: nonce, childrenHashes: finalChildHashes, children: childBlocks, hash: hash)
        }
        guard let definition = extractDefinition() else { return nil }
        guard let transactions = extractTransactions() else { return nil }
        guard let geneses = extractGenesis(transactions: transactions) else { return nil }
        let genesisBlocks = geneses.elements().reduce(Mapping<String, BlockType>()) { (result, entry) -> Mapping<String, BlockType>? in
            guard let result = result else { return nil }
            guard let genesisBlock = entry.1.toGenesis() else { return nil }
            return result.setting(key: entry.0, value: genesisBlock)
        }
        guard let finalGenesisBlocks = genesisBlocks else { return nil }
        let combinedHashes = finalGenesisBlocks.elements().reduce(finalChildHashes) { (result, entry) -> Mapping<String, Digest>? in
            guard let result = result else { return nil }
            guard let childHash = entry.1.hash else { return nil }
            return result.setting(key: entry.0, value: childHash)
        }
        guard let finalCombinedHashes = combinedHashes else { return nil }
        return BlockType(body: BlockBodyType(transactions: transactions, definition: definition), definitionHash: definitionRoot.digest, nextDifficulty: nextDifficulty, index: index, timestamp: timestamp, previous: previous, homestead: homestead, parentHomestead: parentHomestead, frontier: frontier, genesis: finalGenesisBlocks, nonce: nonce, childrenHashes: finalCombinedHashes, children: childBlocks, hash: hash)
    }
    
    static func getFrontier(homestead: Digest, transactionsRoot: TransactionArrayAddress) -> State.CoreType? {
        guard let transactions = Self.extractTransactions(transactionsRoot: transactionsRoot) else { return nil }
        return Self.getFrontier(homestead: homestead, transactions: transactions)
    }

    static func getFrontierDigest(homestead: Digest, transactionsRoot: TransactionArrayAddress) -> Digest? {
        return getFrontier(homestead: homestead, transactionsRoot: transactionsRoot)?.root.digest
    }
    
    static func getFrontier(homestead: Digest, transactions: [TransactionType]) -> State.CoreType? {
        let allActions = transactions.map { $0.allActions() }.reduce([], +)
        let allStateData = transactions.map { $0.stateData }.reduce([], +)
        let nonDeletionActions = allActions.reduce(Mapping<String, Data>()) { (result, entry) -> Mapping<String, Data>?
            in
            guard let result = result else { return nil }
            guard let new = entry.new else { return result }
            return result.setting(key: entry.key, value: new)
        }
        let deletionActions = allActions.reduce([]) { (result, entry) -> [String]?
            in
            guard let result = result else { return nil }
            if entry.new != nil { return result }
            return result + [entry.key]
        }
        guard let emptyState = State(da: [:]) else { return nil }
        guard let initialCoreState = (homestead == emptyRoot() ? emptyState.core.capture(info: []) : State.CoreType(root: State.CoreRoot(digest: homestead)).mask().0.capture(info: allStateData)) else { return nil }
        guard let nonDeletions = nonDeletionActions else { return nil }
        guard let deletions = deletionActions else { return nil }
        let stateAfterNonDeletionActions = nonDeletions.elements().reduce(initialCoreState.0) { (result, entry) -> State.CoreType? in
            guard let result = result else { return nil }
            let dataScalar: DataScalar = DataScalar(scalar: entry.1)
            guard let dataAddress = DataAddress(artifact: dataScalar, complete: true) else { return nil }
            return result.setting(key: entry.0, to: dataAddress.empty())
        }
        guard let stateAfterNonDeletions = stateAfterNonDeletionActions else { return nil }
        let stateAfterDeletionActions = deletions.reduce(stateAfterNonDeletions) { (result, entry) -> State.CoreType? in
            guard let result = result else { return nil }
            return result.deleting(key: entry)
        }
        return stateAfterDeletionActions
    }
    
    static func getFrontierDigest(homestead: Digest, transactions: [TransactionType]) -> Digest? {
        return getFrontier(homestead: homestead, transactions: transactions)?.root.digest
    }
    
    func verifyFrontierState(homestead: Digest, transactions: [TransactionType]) -> Bool {
        guard let calculatedFrontier = Self.getFrontierDigest(homestead: homestead, transactions: transactions) else { return false }
        return calculatedFrontier == frontier
    }
    
    func toGenesis() -> BlockType? {
        if previousRoot != nil { return nil }
        guard let definition = extractDefinition() else { return nil }
        guard let transactions = extractTransactions() else { return nil }
        guard let hash = hash() else { return nil }
        return BlockType(body: BlockBodyType(transactions: transactions, definition: definition), definitionHash: definitionRoot.digest, nextDifficulty: nextDifficulty, index: index, timestamp: timestamp, previous: nil, homestead: homestead, parentHomestead: parentHomestead, frontier: frontier, genesis: Mapping<String, BlockType>(), nonce: nonce, childrenHashes: Mapping<String, Digest>(), children: Mapping<String, BlockType>(), hash: hash)
    }
    
    func proofOfWork() -> Digest? {
        guard let previousAddress = previousRoot else { return nil }
        let input = transactionsRoot.digest.toBoolArray() + definitionRoot.digest.toBoolArray() + String(describing: timestamp).toBoolArray() + previousAddress.digest.toBoolArray()
        let appendedInput = input + (homestead.toBoolArray() + (parentHomestead == nil ? [true] : parentHomestead!.toBoolArray()) + frontier.toBoolArray() + nonce.toBoolArray() + (index == Digest(0) ? [] : nextDifficulty.toBoolArray()))
        guard let hashedInput = CryptoDelegateType.hash(appendedInput) else { return nil }
        return Digest(raw: hashedInput)
    }
    
    func extractGenesis(transactions: [TransactionType]) -> Mapping<String, Self>? {
        let allGenesisActions = transactions.map { $0.genesisActions }.reduce([], +)
        return allGenesisActions.reduce(Mapping<String, Self>()) { (result, entry) -> Mapping<String, Self>? in
            guard let result = result else { return nil }
            guard let blockArtifact = Self(data: entry.genesisData) else { return nil }
            if !blockArtifact.isComplete() { return nil }
            return result.setting(key: entry.directory, value: blockArtifact)
        }
    }
    
    func extractDefinition() -> DefinitionType? {
        guard let definitionArtifact = definitionRoot.artifact else { return nil }
        return definitionArtifact.toDefinition()
    }
    
    static func extractTransactions(transactionsRoot: TransactionArrayAddress) -> [TransactionType]? {
        if !transactionsRoot.complete { return nil }
        return transactionsRoot.artifact!.children.elements().reduce([]) { (result, entry) -> [TransactionType]? in
            guard let result = result else { return nil }
            guard let artifact = entry.1.artifact else { return nil }
            guard let transaction = artifact.convertToTransaction() else { return nil }
            return result + [transaction]
        }
    }
    
    func extractTransactions() -> [TransactionType]? {
        return Self.extractTransactions(transactionsRoot: transactionsRoot)
    }
    
    static func convert(transactionArtifacts: [TransactionArtifactType]) -> TransactionArrayAddress? {
        guard let transactionArrayArtifact = TransactionArray(artifacts: transactionArtifacts) else { return nil }
        return TransactionArrayAddress(artifact: transactionArrayArtifact, complete: true)
    }

    func backwardsChain(hash: Digest) -> BlockType {
        guard let previousBlockRoot = previousRoot, let previousBlockArtifact = previousBlockRoot.artifact else {
            return BlockType(body: nil, definitionHash: definitionRoot.digest, nextDifficulty: nextDifficulty, index: index, timestamp: timestamp, previous: nil, homestead: homestead, parentHomestead: parentHomestead, frontier: frontier, genesis: Mapping<String, BlockType>(), nonce: nonce, childrenHashes: Mapping<String, Digest>(), children: Mapping<String, BlockType>(), hash: hash)
        }
        let previousBackwardsChain = previousBlockArtifact.backwardsChain(hash: previousBlockRoot.digest)
        return BlockType(body: nil, definitionHash: definitionRoot.digest, nextDifficulty: nextDifficulty, index: index, timestamp: timestamp, previous: previousBackwardsChain, homestead: homestead, parentHomestead: parentHomestead, frontier: frontier, genesis: Mapping<String, BlockType>(), nonce: nonce, childrenHashes: Mapping<String, Digest>(), children: Mapping<String, BlockType>(), hash: hash)
    }
}
