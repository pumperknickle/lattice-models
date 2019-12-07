import Foundation
import Bedrock
import JavaScriptCore
import Regenerate
import CryptoStarterPack
import AwesomeTrie
import AwesomeDictionary

public protocol BlockArtifact {
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
    
    typealias BinaryScalar = TransactionArtifactType.BinaryScalar
    typealias BinaryAddress = TransactionArtifactType.BinaryAddress
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
    var parentHomestead: Digest? { get }
    var frontier: Digest! { get }
    var nonce: Digest! { get }
    var children: BlockDictionaryAddress! { get }
    
    func toBlock() -> BlockType
    func hash() -> Digest?
}

public extension BlockArtifact {
    func hash() -> Digest? {
        return BlockAddress(artifact: self, symmetricKeyHash: nil, symmetricIV: nil, complete: true)?.digest
    }
    
    func toBlock(proofOfWork: Digest) -> BlockType? {
        guard let previousRoot = previousRoot else { return nil }
        let previous = previousRoot.artifact?.backwardsChain(hash: previousRoot.digest)
        guard let previousDifficulty = previousRoot.artifact?.nextDifficulty else { return nil }
        guard let hash = hash() else { return nil }
        if proofOfWork <= previousDifficulty {
            guard let definition = extractDefinition() else { return nil }
            guard let transactions = extractTransactions() else { return nil }
            guard let genesis = extractGenesis(transactions: transactions) else { return nil }
            let childrenHashes = genesis.elements().reduce(Mapping<String, Digest>()) { (result, entry) -> Mapping<String, Digest>? in
                guard let result = result else { return nil }
                guard let childHash = entry.1.hash() else { return nil }
                return result.setting(key: entry.0, value: childHash)
            }
            guard let finalChildrenHashes = childrenHashes else { return nil }
            let transformedGenesis = genesis.elements().reduce(Mapping<String, BlockType>()) { (result, entry) -> Mapping<String, BlockType>? in
                guard let result = result else { return nil }
                guard let genesisBlock = entry.1.toGenesis() else { return nil }
                return result.setting(key: entry.0, value: genesisBlock)
            }
            guard let finalGenesis = transformedGenesis else { return nil }
            return BlockType(transactions: transactions, definition: definition, nextDifficulty: nextDifficulty, index: index, previous: previous, homestead: homestead, parentHomestead: parentHomestead, frontier: frontier, genesis: finalGenesis, nonce: nonce, proofOfWork: nil, childrenHashes: finalChildrenHashes, children: Mapping<String, BlockType>(), proofOfWorkExceedsDifficulty: true, hash: hash)
        }
        return BlockType(transactions: [], definition: nil, nextDifficulty: nextDifficulty, index: index, previous: previous, homestead: homestead, parentHomestead: parentHomestead, frontier: frontier, genesis: Mapping<String, BlockType>(), nonce: nonce, proofOfWork: nil, childrenHashes: Mapping<String, Digest>(), children: Mapping<String, BlockType>(), proofOfWorkExceedsDifficulty: false, hash: hash)
    }
    
    func verifyFrontierState(transactions: [TransactionType]) -> Bool {
        let allActions = transactions.map { $0.allActions() }.reduce([], +)
        let allStateData = transactions.map { $0.stateData }.reduce([], +)
        let nonDeletionActions = allActions.reduce(Mapping<String, BinaryAddress>()) { (result, entry) -> Mapping<String, BinaryAddress>?
            in
            guard let result = result else { return nil }
            if entry.new.isEmpty { return result }
            guard let key = String(raw: entry.key) else { return nil }
            let binaryScalar = BinaryScalar(scalar: entry.new)
            guard let binaryAddress = BinaryAddress(artifact: binaryScalar, symmetricKeyHash: nil, symmetricIV: nil, complete: true) else { return nil }
            return result.setting(key: key, value: binaryAddress)
        }
        let deletionActions = allActions.reduce([]) { (result, entry) -> [String]?
            in
            guard let result = result else { return nil }
            if !entry.new.isEmpty { return result }
            guard let key = String(raw: entry.key) else { return nil }
            return result + [key]
        }
        guard let initialCoreState = State.CoreType(root: State.CoreRoot(digest: homestead, symmetricKeyHash: nil, symmetricIV: nil)).capture(info: allStateData, previousKey: nil, keys: TrieMapping<Bool, [Bool]>()) else { return false }
        guard let nonDeletions = nonDeletionActions else { return false }
        guard let deletions = deletionActions else { return false }
        let stateAfterNonDeletionActions = nonDeletions.elements().reduce(initialCoreState.0) { (result, entry) -> State.CoreType? in
            guard let result = result else { return nil }
            return result.setting(key: entry.0, to: entry.1)
        }
        guard let stateAfterNonDeletions = stateAfterNonDeletionActions else { return false }
        let stateAfterDeletionActions = deletions.reduce(stateAfterNonDeletions) { (result, entry) -> State.CoreType? in
            guard let result = result else { return nil }
            return result.deleting(key: entry)
        }
        return stateAfterDeletionActions == nil ? false : stateAfterDeletionActions!.root.digest == frontier
    }
    
    func toGenesis() -> BlockType? {
        if previousRoot != nil { return nil }
        guard let definition = extractDefinition() else { return nil }
        guard let transactions = extractTransactions() else { return nil }
        guard let hash = hash() else { return nil }
        return BlockType(transactions: transactions, definition: definition, nextDifficulty: nextDifficulty, index: index, previous: nil, homestead: homestead, parentHomestead: parentHomestead, frontier: frontier, genesis: Mapping<String, BlockType>(), nonce: nonce, proofOfWork: nil, childrenHashes: Mapping<String, Digest>(), children: Mapping<String, BlockType>(), proofOfWorkExceedsDifficulty: true, hash: hash)
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
            guard let blockArtifact = Self(raw: entry.genesisBinary) else { return nil }
            if !blockArtifact.isComplete() { return nil }
            return result.setting(key: entry.directory, value: blockArtifact)
        }
    }
    
    func extractDefinition() -> DefinitionType? {
        guard let definitionArtifact = definitionRoot.artifact else { return nil }
        return definitionArtifact.toDefinition()
    }
    
    func extractTransactions() -> [TransactionType]? {
        if !transactionsRoot.complete { return nil }
        let transactions = transactionsRoot.artifact!.children.elements().map { $0.1.artifact!.convertToTransaction() }
        if transactions.contains(nil) { return nil }
        return transactions.map { $0! }
    }
    
    func backwardsChain(hash: Digest) -> BlockType {
        guard let previousBlockRoot = previousRoot, let previousBlockArtifact = previousBlockRoot.artifact else {
            return BlockType(transactions: [], definition: nil, nextDifficulty: nextDifficulty, index: index, previous: nil, homestead: homestead, parentHomestead: parentHomestead, frontier: frontier, genesis: Mapping<String, BlockType>(), nonce: nonce, proofOfWork: nil, childrenHashes: Mapping<String, Digest>(), children: Mapping<String, BlockType>(), proofOfWorkExceedsDifficulty: true, hash: hash)
        }
        let previousBackwardsChain = previousBlockArtifact.backwardsChain(hash: previousBlockRoot.digest)
        return BlockType(transactions: [], definition: nil, nextDifficulty: nextDifficulty, index: index, previous: previousBackwardsChain, homestead: homestead, parentHomestead: parentHomestead, frontier: frontier, genesis: Mapping<String, BlockType>(), nonce: nonce, proofOfWork: nil, childrenHashes: Mapping<String, Digest>(), children: Mapping<String, BlockType>(), proofOfWorkExceedsDifficulty: true, hash: hash)
    }
}
