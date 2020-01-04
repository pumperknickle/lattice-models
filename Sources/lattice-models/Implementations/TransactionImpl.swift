import Foundation
import Bedrock
import CryptoStarterPack
import AwesomeDictionary

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
    private let rawSignatures: Mapping<Data, Data>!
    private let rawFee: Digest!
    private let rawParentHomesteadRoot: Digest?
    private let rawTransactionHash: Digest!
    private let rawStateDelta: Digest!
    private let rawStateData: [Data]!
    
    public init(unreservedActions: [ActionImpl], accountActions: [AccountImpl], receiptActions: [ReceiptImpl], depositActions: [DepositImpl], genesisActions: [GenesisImpl], seedActions: [SeedImpl], peerActions: [PeerImpl], parentReceipts: [ReceiptImpl], signers: Set<UInt256>, signatures: Mapping<Data, Data>, fee: UInt256, parentHomesteadRoot: UInt256?, transactionHash: UInt256, stateDelta: UInt256, stateData: [Data]) {
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
    public var signatures: Mapping<Data, Data>! { return rawSignatures }
    public var fee: Digest! { return rawFee }
    public var parentHomesteadRoot: Digest? { return rawParentHomesteadRoot }
    public var transactionHash: Digest! { return rawTransactionHash }
    public var stateDelta: Digest! { return rawStateDelta }
    public var stateData: [Data]! { return rawStateData }
    
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
