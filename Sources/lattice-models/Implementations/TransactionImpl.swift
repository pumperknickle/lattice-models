import Foundation
import Bedrock
import CryptoStarterPack
import AwesomeTrie

public struct TransactionImpl: Codable {
    private let rawUnreservedActions: [ActionImpl]!
    private let rawAccountActions: [AccountImpl]!
    private let rawReceiptActions: [ReceiptImpl]!
    private let rawDepositActions: [DepositImpl]!
    private let rawGenesisActions: [GenesisImpl]!
    private let rawSeedActions: [SeedImpl]!
    private let rawPeerActions: [PeerImpl]!
    private let rawParentReceipts: [ReceiptImpl]!
    private let rawSigners: Set<Digest>!
    private let rawSignatures: TrieMapping<Bool, [Bool]>!
    private let rawFee: Digest!
    private let rawParentHomesteadRoot: Digest?
    private let rawTransactionHash: Digest!
    private let rawStateDelta: Digest!
    private let rawStateData: [[Bool]]!
    
    public init(unreservedActions: [ActionImpl], accountActions: [AccountImpl], receiptActions: [ReceiptImpl], depositActions: [DepositImpl], genesisActions: [GenesisImpl], seedActions: [SeedImpl], peerActions: [PeerImpl], parentReceipts: [ReceiptImpl], signers: Set<UInt256>, signatures: TrieMapping<Bool, [Bool]>, fee: UInt256, parentHomesteadRoot: UInt256?, transactionHash: UInt256, stateDelta: UInt256, stateData: [[Bool]]) {
        rawUnreservedActions = unreservedActions
        rawAccountActions = accountActions
        rawReceiptActions = receiptActions
        rawDepositActions = depositActions
        rawGenesisActions = genesisActions
        rawSeedActions = seedActions
        rawPeerActions = peerActions
        rawParentReceipts = parentReceipts
        rawSigners = signers
        rawSignatures = signatures
        rawFee = fee
        rawParentHomesteadRoot = parentHomesteadRoot
        rawTransactionHash = transactionHash
        rawStateDelta = stateDelta
        rawStateData = stateData
    }
}

extension TransactionImpl: BinaryEncodable {
    public func toBoolArray() -> [Bool] {
        return try! JSONEncoder().encode(self).toBoolArray()
    }
    
    public init?(raw: [Bool]) {
        guard let data = Data(raw: raw) else { return nil }
        guard let decoded = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = decoded
    }
}

extension TransactionImpl: Transaction {
    public var unreservedActions: [ActionImpl]! { return rawUnreservedActions }
    public var accountActions: [AccountImpl]! { return rawAccountActions }
    public var receiptActions: [ReceiptImpl]! { return rawReceiptActions }
    public var depositActions: [DepositImpl]! { return rawDepositActions }
    public var genesisActions: [GenesisImpl]! { return rawGenesisActions }
    public var seedActions: [SeedImpl]! { return rawSeedActions }
    public var peerActions: [PeerImpl]! { return rawPeerActions }
    public var parentReceipts: [ReceiptImpl]! { return rawParentReceipts }
    public var signers: Set<Digest>! { return rawSigners }
    public var signatures: TrieMapping<Bool, [Bool]>! { return rawSignatures }
    public var fee: Digest! { return rawFee }
    public var parentHomesteadRoot: Digest? { return rawParentHomesteadRoot }
    public var transactionHash: Digest! { return rawTransactionHash }
    public var stateDelta: Digest! { return rawStateDelta }
    public var stateData: [[Bool]]! { return rawStateData }
    
    public typealias ActionType = ActionImpl
    public typealias Digest = UInt256
    public typealias DemandType = DemandImpl
    public typealias SendableType = SendableImpl
    public typealias AccountType = AccountImpl
    public typealias ReceiptType = ReceiptImpl
    public typealias DepositType = DepositImpl
    public typealias GenesisType = GenesisImpl
    public typealias SeedType = SeedImpl
    public typealias PeerType = PeerImpl
    public typealias CryptoDelegateType = BaseCrypto
    public typealias AsymmetricDelegateType = BaseAsymmetric
}
