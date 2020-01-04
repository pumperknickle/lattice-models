import Foundation
import Bedrock
import JavaScriptCore
import CryptoStarterPack
import AwesomeDictionary
import AwesomeTrie

public protocol Transaction: Codable {
    associatedtype ActionType
    associatedtype Digest
    associatedtype DemandType where DemandType.Digest == Digest
    associatedtype SendableType
    
    associatedtype AccountType: Account where AccountType.ActionType == ActionType, AccountType.Digest == Digest
    associatedtype ReceiptType: Receipt where ReceiptType.ActionType == ActionType, ReceiptType.Digest == Digest, ReceiptType.DemandType == DemandType
    associatedtype DepositType: Deposit where DepositType.ActionType == ActionType, DepositType.Digest == Digest, DepositType.DemandType == DemandType
    associatedtype GenesisType: Genesis where GenesisType.ActionType == ActionType
    associatedtype SeedType: Seed where SeedType.ActionType == ActionType, SeedType.SendableType == SendableType
    associatedtype PeerType: Peer where PeerType.ActionType == ActionType, PeerType.Digest == Digest, PeerType.SendableType == SendableType
    
    associatedtype CryptoDelegateType: CryptoDelegate
    associatedtype AsymmetricDelegateType: AsymmetricDelegate
    
    var unreservedActions: [ActionType]! { get }
    var accountActions: [AccountType]! { get }
    var receiptActions: [ReceiptType]! { get }
    var depositActions: [DepositType]! { get }
    var genesisActions: [GenesisType]! { get }
    var seedActions: [SeedType]! { get }
    var peerActions: [PeerType]! { get }
    var parentReceipts: [ReceiptType]! { get }
    var signers: Set<Digest>! { get }
    var signatures: Mapping<Data, Data>! { get }
    var fee: Digest! { get }
    var parentHomesteadRoot: Digest? { get }
    var transactionHash: Digest! { get }
    var stateDelta: Digest! { get }
    var stateData: [Data]! { get }
    
    func allActions() -> [ActionType]
        
    init(unreservedActions: [ActionType], accountActions: [AccountType], receiptActions: [ReceiptType], depositActions: [DepositType], genesisActions: [GenesisType], seedActions: [SeedType], peerActions: [PeerType], parentReceipts: [ReceiptType], signers: Set<Digest>, signatures: Mapping<Data, Data>, fee: Digest, parentHomesteadRoot: Digest?, transactionHash: Digest, stateDelta: Digest, stateData: [Data])
}

public extension Transaction {
    func allActions() -> [ActionType] {
        let firstSet = unreservedActions + accountActions.map { $0.toAction() } + receiptActions.map { $0.toAction() } + depositActions.map { $0.toAction() }
        return firstSet + genesisActions.map { $0.toAction() } + seedActions.map { $0.toAction() } + peerActions.map { $0.toAction() }
    }
    
    func changing(unreservedActions: [ActionType]? = nil, accountActions: [AccountType]? = nil, receiptActions: [ReceiptType]? = nil, depositActions: [DepositType]? = nil, genesisActions: [GenesisType]? = nil, seedActions: [SeedType]? = nil, peerActions: [PeerType]? = nil, parentReceipts: [ReceiptType]? = nil, stateData: [Data]? = nil) -> Self {
        return Self(unreservedActions: unreservedActions ?? self.unreservedActions, accountActions: accountActions ?? self.accountActions, receiptActions: receiptActions ?? self.receiptActions, depositActions: depositActions ?? self.depositActions, genesisActions: genesisActions ?? self.genesisActions, seedActions: seedActions ?? self.seedActions, peerActions: peerActions ?? self.peerActions, parentReceipts: parentReceipts ?? self.parentReceipts, signers: signers, signatures: signatures, fee: fee, parentHomesteadRoot: parentHomesteadRoot, transactionHash: transactionHash, stateDelta: stateDelta, stateData: stateData ?? self.stateData)
    }
    
    func verifyFee() -> Bool {
        return fee! + newBalances() <= oldBalances() || fee == 0
    }
    
    // Used by miners to verify outside transactions fees
    func verifyOutsideTransactionFee() -> Bool {
        return fee! + newBalances() <= oldBalances()
    }
    
    func newBalances() -> Digest {
        let accountNewBalances = accountActions.map { $0.newBalance }.reduce(Digest(0), +)
        return depositActions.map { $0.newBalance }.reduce(accountNewBalances, +)
    }
    
    func oldBalances() -> Digest {
        let accountOldBalances = accountActions.map { $0.oldBalance }.reduce(Digest(0), +)
        return depositActions.map { $0.oldBalance }.reduce(accountOldBalances, +)
    }
    
    func verifyAll(filters: [String]) -> Bool {
        if !verifySignatures() { return false }
        if !verifyAccounts() { return false }
        if !verifyReceipts() { return false }
        if !verifyDeposits() { return false }
        if !verifyParentReceipts() { return false }
        if !verifyPeers() { return false }
        if !verifyFee() { return false }
        if !verify(filters: filters) { return false }
        return true
    }
    
    func verifySignatures() -> Bool {
        let message = transactionHash.toData()
        return signatures.elements().reduce(true) { (result, entry) -> Bool in
            return result && AsymmetricDelegateType.verify(message: message, publicKey: entry.0, signature: entry.1)
        }
    }
    
    func verifyAccounts() -> Bool {
        return !accountActions.contains(where: { $0.newBalance <= $0.oldBalance && !signers.contains($0.address) })
    }
    
    func verifyReceipts() -> Bool {
        let accountMapping = accountActions.reduce(Mapping<Digest, AccountType>()) { (result, entry) -> Mapping<Digest, AccountType> in
            return result.setting(key: entry.address, value: entry)
        }
        return !receiptActions.contains(where: {
            guard let account = accountMapping[$0.demand.recipient] else { return true }
            return account.newBalance < $0.demand.amount + account.oldBalance
        })
    }
    
    func verifyDeposits() -> Bool {
        let parentMapping = parentReceipts.reduce(Mapping<DemandType, ReceiptType>()) { (result, entry) -> Mapping<DemandType, ReceiptType> in
            return result.setting(key: entry.demand, value: entry)
        }
        return !depositActions.contains(where: { $0.oldBalance > $0.newBalance && parentMapping[$0.demand] == nil })
    }
    
    func verifyParentReceipts() -> Bool {
        return !parentReceipts.contains(where: { !signers.contains($0.sender) })
    }
    
    func verifyPeers() -> Bool {
        return !peerActions.contains(where: { !signers.contains($0.address) })
    }
    
    func verify(filters: [String]) -> Bool {
        return !filters.contains(where: { return !verify(filter: $0)  })
    }
    
    func verify(filter: String) -> Bool {
        guard let context = JSContext() else { return false }
        guard let transactionData = try? JSONEncoder().encode(self) else { return false }
        guard let transactionJSON = String(bytes: transactionData, encoding: .utf8) else { return false }
        context.evaluateScript(filter)
        guard let transactionFilter = context.objectForKeyedSubscript("transactionFilter") else { return false }
        guard let result = transactionFilter.call(withArguments: [transactionJSON]) else { return false }
        return result.isBoolean ? result.toBool() : false
    }
}
