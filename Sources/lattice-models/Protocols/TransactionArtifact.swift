import Foundation
import Bedrock
import JavaScriptCore
import Regenerate
import CryptoStarterPack
import AwesomeTrie
import AwesomeDictionary

public protocol TransactionArtifact: RGArtifact {
    associatedtype Digest
    associatedtype AsymmetricDelegateType
    associatedtype CryptoDelegateType
    associatedtype TransactionType: Transaction where TransactionType.ActionType == ActionType, TransactionType.Digest == Digest, TransactionType.AsymmetricDelegateType == AsymmetricDelegateType, TransactionType.CryptoDelegateType == CryptoDelegateType
    
    associatedtype ActionType
    associatedtype ActionScalar: RGScalar where ActionScalar.T == ActionType
    associatedtype ActionAddress where ActionAddress.Artifact == ActionScalar, ActionAddress.Digest == Digest, ActionAddress.CryptoDelegateType == CryptoDelegateType
    associatedtype ActionArray: RGArray where ActionArray.Element == ActionAddress
    associatedtype ActionArrayAddress: Addressable where ActionArrayAddress.Artifact == ActionArray, ActionArrayAddress.Digest == Digest, ActionArrayAddress.CryptoDelegateType == CryptoDelegateType
    
    associatedtype DataScalar: RGScalar where DataScalar.T == Data
    associatedtype DataAddress where DataAddress.Artifact == DataScalar, DataAddress.Digest == Digest, DataAddress.CryptoDelegateType == CryptoDelegateType
    associatedtype DataArray: RGArray where DataArray.Element == DataAddress
    associatedtype DataArrayAddress: Addressable where DataArrayAddress.Artifact == DataArray, DataArrayAddress.Digest == Digest, DataArrayAddress.CryptoDelegateType == CryptoDelegateType
    
    associatedtype State: RGDictionary where State.Key == String, State.Value == DataAddress, State.CoreType.Digest == Digest
    associatedtype StateAddress where StateAddress.Artifact == State, StateAddress.Digest == Digest, StateAddress.CryptoDelegateType == CryptoDelegateType
    associatedtype StateObject: Regenerative where StateObject.Root == StateAddress
    
    typealias ReceiptType = TransactionType.ReceiptType
    typealias AccountType = TransactionType.AccountType
    typealias DepositType = TransactionType.DepositType
    typealias GenesisType = TransactionType.GenesisType
    typealias SeedType = TransactionType.SeedType
    typealias PeerType = TransactionType.PeerType
    
    var actionsRoot: ActionArrayAddress! { get }
    var fee: Digest! { get }
    var previousHash: Digest? { get }
    var publicKeysRoot: DataArrayAddress! { get }
    var signaturesRoot: DataArrayAddress! { get }
    var homesteadRoot: Digest! { get }
    var homesteadDataRoot: DataArrayAddress! { get }
    var parentHomesteadRoot: Digest? { get }
    var parentReceiptRoot: DataArrayAddress! { get }
    
    static func actionsProperty() -> String
    static func publicKeysProperty() -> String
    static func signaturesProperty() -> String
    static func homesteadDataProperty() -> String
    static func parentReceiptProperty() -> String
    
    init(actionsRoot: ActionArrayAddress, fee: Digest, previousHash: Digest?, publicKeysRoot: DataArrayAddress, signaturesRoot: DataArrayAddress, homesteadRoot: Digest, homesteadDataRoot: DataArrayAddress, parentHomesteadRoot: Digest?, parentReceiptRoot: DataArrayAddress)
}

public extension TransactionArtifact {
    init?(actions: [ActionType], fee: Digest, previousHash: Digest?, publicKeySignatures: Mapping<Data, Data>, homesteadState: StateObject, parentHomesteadState: StateObject? = nil, parentReceipts: [ReceiptType] = [], publicKey: Data, privateKey: Data) {
        let keySigPairs = publicKeySignatures.elements()
        let publicKeys = keySigPairs.map { $0.0 } + [publicKey]
        guard let transactionToSign = Self(actions: actions, fee: fee, previousHash: previousHash, publicKeys: publicKeys, homesteadState: homesteadState, parentHomesteadState: parentHomesteadState, parentReceipts: parentReceipts) else { return nil }
        guard let transactionHash = transactionToSign.calculateTransactionHash() else { return nil }
        guard let signature = AsymmetricDelegateType.sign(message: transactionHash.toData(), privateKey: privateKey) else { return nil }
        let signatures = publicKeySignatures.values() + [signature]
        guard let actionsRoot = Self.convert(actions: actions) else { return nil }
        guard let publicKeysRoot = Self.convert(allBinaries: publicKeys) else { return nil }
        guard let signaturesRoot = Self.convert(allBinaries: signatures) else { return nil }
        guard let homesteadRoot = homesteadState.root.artifact?.core.root.digest else { return nil }
        guard let homesteadData = Self.convert(homesteadState: homesteadState, actions: actions) else { return nil }
        guard let homesteadDataRoot = Self.convert(allBinaries: homesteadData) else { return nil }
        if let parentHomestead = parentHomesteadState {
            guard let parentReceiptRoot = Self.extractParentReceiptsRoot(parentHomestead: parentHomestead, parentReceipts: parentReceipts) else { return nil }
            guard let parentHomesteadRoot = parentHomestead.root.artifact?.core.root.digest else { return nil }
            self = Self(actionsRoot: actionsRoot, fee: fee, previousHash: previousHash, publicKeysRoot: publicKeysRoot, signaturesRoot: signaturesRoot, homesteadRoot: homesteadRoot, homesteadDataRoot: homesteadDataRoot, parentHomesteadRoot: parentHomesteadRoot, parentReceiptRoot: parentReceiptRoot)
        }
        self = Self(actionsRoot: actionsRoot, fee: fee, previousHash: previousHash, publicKeysRoot: publicKeysRoot, signaturesRoot: signaturesRoot, homesteadRoot: homesteadRoot, homesteadDataRoot: homesteadDataRoot, parentHomesteadRoot: nil, parentReceiptRoot: Self.emptyRoot()!)
    }
    
    init?(actions: [ActionType], fee: Digest, previousHash: Digest?, publicKeys: [Data], homesteadState: StateObject, parentHomesteadState: StateObject? = nil, parentReceipts: [ReceiptType] = []) {
        guard let actionsRoot = Self.convert(actions: actions) else { return nil }
        guard let publicKeysRoot = Self.convert(allBinaries: publicKeys) else { return nil }
        guard let homesteadData = Self.convert(homesteadState: homesteadState, actions: actions) else { return nil }
        guard let homesteadDataRoot = Self.convert(allBinaries: Array(homesteadData)) else { return nil }
        guard let homesteadRoot = homesteadState.root.artifact?.core.root.digest else { return nil }
        if let parentHomesteadState = parentHomesteadState {
            guard let parentReceiptRoot = Self.convert(parentHomesteadState: parentHomesteadState, parentReceipts: parentReceipts) else { return nil }
            guard let parentHomesteadRoot = parentHomesteadState.root.artifact?.core.root.digest else { return nil }
            self = Self(actionsRoot: actionsRoot, fee: fee, previousHash: previousHash, publicKeysRoot: publicKeysRoot, signaturesRoot: Self.emptyRoot()!, homesteadRoot: homesteadRoot, homesteadDataRoot: homesteadDataRoot, parentHomesteadRoot: parentHomesteadRoot, parentReceiptRoot: parentReceiptRoot)
        }
        guard let emptyRoot = Self.emptyRoot() else { return nil }
        self = Self(actionsRoot: actionsRoot, fee: fee, previousHash: previousHash, publicKeysRoot: publicKeysRoot, signaturesRoot: emptyRoot, homesteadRoot: homesteadRoot, homesteadDataRoot: homesteadDataRoot, parentHomesteadRoot: nil, parentReceiptRoot: emptyRoot)
    }
    
    init?(actions: [ActionType], fee: Digest, previousHash: Digest?, publicKeySignatures: Mapping<Data, Data>, homesteadState: StateObject, parentHomesteadState: StateObject? = nil, parentReceipts: [ReceiptType] = []) {
        guard let actionsRoot = Self.convert(actions: actions) else { return nil }
        let keySigPairs = publicKeySignatures.elements()
        let keys = keySigPairs.map { $0.0 }
        let signatures = keySigPairs.map { $0.1 }
        guard let publicKeysRoot = Self.convert(allBinaries: keys) else { return nil }
        guard let signaturesroot = Self.convert(allBinaries: signatures) else { return nil }
        guard let homesteadData = Self.convert(homesteadState: homesteadState, actions: actions) else { return nil }
        guard let homesteadDataRoot = Self.convert(allBinaries: homesteadData) else { return nil }
        guard let parentHomesteadState = parentHomesteadState else {
            guard let emptyRoot = Self.emptyRoot() else { return nil }
            self = Self(actionsRoot: actionsRoot, fee: fee, previousHash: previousHash, publicKeysRoot: publicKeysRoot, signaturesRoot: signaturesroot, homesteadRoot: homesteadState.root.digest, homesteadDataRoot: homesteadDataRoot, parentHomesteadRoot: nil, parentReceiptRoot: emptyRoot)
            return
        }
        guard let parentReceiptRoot = Self.convert(parentHomesteadState: parentHomesteadState, parentReceipts: parentReceipts) else { return nil }
        self = Self(actionsRoot: actionsRoot, fee: fee, previousHash: previousHash, publicKeysRoot: publicKeysRoot, signaturesRoot: signaturesroot, homesteadRoot: homesteadState.root.digest, homesteadDataRoot: homesteadDataRoot, parentHomesteadRoot: parentHomesteadState.root.digest, parentReceiptRoot: parentReceiptRoot)
    }
    
    static func emptyRoot() -> DataArrayAddress? {
        guard let emptyArray = DataArray([]) else { return nil }
        return DataArrayAddress(artifact: emptyArray, complete: true)
    }
    
    static func convert(parentHomesteadState: StateObject, parentReceipts: [ReceiptType]) -> DataArrayAddress? {
        let keys = parentReceipts.reduce([]) { (result, entry) -> [String]? in
            guard let result = result else { return nil }
            return result + [entry.toAction().key]
        }
        guard let unwrappedKeys = keys else { return nil }
        let allContents = parentHomesteadState.contents()
        let targets = unwrappedKeys.reduce(TrieSet<String>()) { (result, entry) -> TrieSet<String> in
            return result.adding([entry])
        }
        let targetedState = parentHomesteadState.empty().targeting(targets).0
        guard let regeneratedState = targetedState.capture(info: allContents.values()) else { return nil }
        return Self.convert(allBinaries: regeneratedState.contents().values())
    }
    
    static func convert(homesteadState: StateObject, actions: [ActionType]) -> [Data]? {
        guard let core = homesteadState.root.artifact?.core else { return nil }
        let transitionState = actions.reduce(core) { (result, entry) -> State.CoreType? in
            guard let result = result else { return nil }
            guard let transitionProof = core.transitionProof(proofType: entry.proofType(), for: entry.key) else { return nil }
            return result.merging(transitionProof)
        }
        guard let unwrappedTransitionState = transitionState else { return nil }
        return unwrappedTransitionState.contents().values()
    }
    
    static func convert(allBinaries: [Data]) -> DataArrayAddress? {
        let dataAddresses = allBinaries.reduce([]) { (result, entry) -> [DataAddress]? in
            guard let result = result else { return nil }
            guard let dataAddress = DataAddress(artifact: DataScalar(scalar: entry), complete: true) else { return nil }
            return result + [dataAddress]
        }
        guard let finalDataAddresses = dataAddresses else { return nil }
        guard let dataArray = DataArray(finalDataAddresses) else { return nil }
        return DataArrayAddress(artifact: dataArray, complete: true)
    }

    static func convert(actions: [ActionType]) -> ActionArrayAddress? {
        let actionScalars = actions.map { ActionScalar(scalar: $0) }
        let actionScalarAddresses = actionScalars.map { ActionAddress(artifact: $0, symmetricKeyHash: nil, symmetricIV: nil) }
        if actionScalarAddresses.contains(nil) { return nil }
        guard let actionArrayArtifact = ActionArray(actionScalarAddresses.map { $0! }) else { return nil }
        return ActionArrayAddress(artifact: actionArrayArtifact, complete: true)
    }
    
    static func actionsProperty() -> String {
        return "actions"
    }
    
    static func publicKeysProperty() -> String {
        return "publicKeys"
    }
    
    static func signaturesProperty() -> String {
        return "signatures"
    }
    
    static func homesteadDataProperty() -> String {
        return "homesteadData"
    }
    
    static func parentReceiptProperty() -> String {
        return "parentReceipt"
    }
    
    func changing(actionsRoot: ActionArrayAddress? = nil, fee: Digest? = nil, publicKeysRoot: DataArrayAddress? = nil, signaturesRoot: DataArrayAddress? = nil, homesteadRoot: Digest? = nil, homesteadDataRoot: DataArrayAddress? = nil, parentReceiptRoot: DataArrayAddress? = nil) -> Self {
        return Self(actionsRoot: actionsRoot ?? self.actionsRoot, fee: fee ?? self.fee, previousHash: previousHash, publicKeysRoot: publicKeysRoot ?? self.publicKeysRoot, signaturesRoot: signaturesRoot ?? self.signaturesRoot, homesteadRoot: homesteadRoot ?? self.homesteadRoot, homesteadDataRoot: homesteadDataRoot ?? self.homesteadDataRoot, parentHomesteadRoot: parentHomesteadRoot, parentReceiptRoot: parentReceiptRoot ?? self.parentReceiptRoot)
    }
    
    func set(property: String, to child: CryptoBindable) -> Self? {
        switch property {
        case Self.actionsProperty():
            guard let newChild = child as? ActionArrayAddress else { return nil }
            return changing(actionsRoot: newChild)
        case Self.publicKeysProperty():
            guard let newChild = child as? DataArrayAddress else { return nil }
            return changing(publicKeysRoot: newChild)
        case Self.signaturesProperty():
            guard let newChild = child as? DataArrayAddress else { return nil }
            return changing(signaturesRoot: newChild)
        case Self.homesteadDataProperty():
            guard let newChild = child as? DataArrayAddress else { return nil }
            return changing(homesteadDataRoot: newChild)
        case Self.parentReceiptProperty():
            guard let newChild = child as? DataArrayAddress else { return nil }
            return changing(parentReceiptRoot: newChild)
        default:
            return nil
        }
    }
    
    func get(property: String) -> CryptoBindable? {
        switch property {
        case Self.actionsProperty():
            return actionsRoot
        case Self.publicKeysProperty():
            return publicKeysRoot
        case Self.signaturesProperty():
            return signaturesRoot
        case Self.homesteadDataProperty():
            return homesteadDataRoot
        case Self.parentReceiptProperty():
            return parentReceiptRoot
        default:
            return nil
        }
    }
    
    static func properties() -> [String] {
        return [actionsProperty(), publicKeysProperty(), signaturesProperty(), homesteadDataProperty(), parentReceiptProperty()]
    }
    
    func convertToTransaction() -> TransactionType? {
        guard let publicKeys = extractPublicKeys() else { return nil }
        guard let signers = Self.extractSigners(publicKeys: publicKeys) else { return nil }
        guard let signatures = extractSignatures() else { return nil }
        if publicKeys.count != signatures.count { return nil }
        let allSignatures = zip(publicKeys, signatures).reduce(Mapping<Data, Data>()) { (result, entry) -> Mapping<Data, Data> in
            return result.setting(key: entry.0, value: entry.1)
        }
        guard let transactionHash = calculateTransactionHash() else { return nil }
        guard let actions = extractActions() else { return nil }
        guard let stateData = extractStateData() else { return nil }
        let emptyTransactionType = TransactionType(unreservedActions: [], accountActions: [], receiptActions: [], depositActions: [], genesisActions: [], seedActions: [], peerActions: [], parentReceipts: [], signers: signers, signatures: allSignatures, fee: fee, parentHomesteadRoot: parentHomesteadRoot, transactionHash:  transactionHash, stateDelta: actions.stateDelta(), stateData: stateData)
        guard let transactionWithoutParentReceipts = add(actions: actions, to: emptyTransactionType) else { return nil }
        if parentHomesteadRoot == nil { return transactionWithoutParentReceipts }
        guard let parentReceiptData = extractParentReceiptsData() else { return nil }
        guard let parentReceipts = extractParentReceipts(data: parentReceiptData) else { return nil }
        return transactionWithoutParentReceipts.changing(parentReceipts: parentReceipts)
    }
        
    func calculateTransactionHash() -> Digest? {
        let firstInput = actionsRoot.digest.toBoolArray() + fee.toBoolArray() + (previousHash?.toBoolArray() ?? []) + publicKeysRoot.digest.toBoolArray()
        let secondInput = homesteadRoot.toBoolArray() + homesteadDataRoot.digest.toBoolArray() + (parentHomesteadRoot?.toBoolArray() ?? []) + parentReceiptRoot.digest.toBoolArray()
        guard let binaryOutput = CryptoDelegateType.hash(firstInput + secondInput) else { return nil }
        return Digest(raw: binaryOutput)
    }
    
    func add(actions: [ActionType], to transaction: TransactionType) -> TransactionType? {
        return actions.reduce(transaction) { (result, entry) -> TransactionType? in
            guard let result = result else { return nil }
            if entry.key.starts(with: ACCOUNT_PREFIX) {
                let account = AccountType(action: entry)
                return account == nil ? nil : result.changing(accountActions: result.accountActions + [account!])
            }
            if entry.key.starts(with: RECEIPTS_PREFIX) {
                let receipt = ReceiptType(action: entry)
                return receipt == nil ? nil : result.changing(receiptActions: result.receiptActions + [receipt!])
            }
            if entry.key.starts(with: DEPOSIT_PREFIX) {
                let deposit = DepositType(action: entry)
                return deposit == nil ? nil : result.changing(depositActions: result.depositActions + [deposit!])
            }
            if entry.key.starts(with: GENESIS_PREFIX) {
                let genesis = GenesisType(action: entry)
                return genesis == nil ? nil : result.changing(genesisActions: result.genesisActions + [genesis!])
            }
            if entry.key.starts(with: SEED_PREFIX) {
                let seed = SeedType(action: entry)
                return seed == nil ? nil : result.changing(seedActions: result.seedActions + [seed!])
            }
            if entry.key.starts(with: PEER_PREFIX) {
                let peer = PeerType(action: entry)
                return peer == nil ? nil : result.changing(peerActions: result.peerActions + [peer!])
            }
            return result.changing(unreservedActions: result.unreservedActions + [entry])
        }
    }
    
    func extractStateData() -> [Data]? {
        let binaries = homesteadDataRoot.artifact?.children.elements().map { $0.1.artifact?.scalar }
        guard let allBinaries = binaries else { return nil }
        return allBinaries.reduce([]) { (result, entry) -> [Data]? in
            guard let result = result else { return nil }
            guard let entry = entry else { return nil }
            return result + [entry]
        }
    }
    
    func extractParentReceiptsData() -> [Data]? {
        let receipts = parentReceiptRoot.artifact?.children.elements().map { $0.1.artifact?.scalar }
        guard let allReceipts = receipts else { return nil }
        return allReceipts.reduce([]) { (result, entry) -> [Data]? in
            guard let result = result else { return nil }
            guard let entry = entry else { return nil }
            return result + [entry]
        }
    }
    
    func extractParentReceipts(data: [Data]) -> [ReceiptType]? {
        guard let parentReceiptsData = extractParentReceiptsData() else { return nil }
        guard let parentHomesteadRoot = parentHomesteadRoot else { return nil }
        let emptyParentState = StateObject(root: StateAddress(digest: parentHomesteadRoot, symmetricKeyHash: nil, symmetricIV: nil))
        guard let regeneratedParentState = emptyParentState.capture(info: parentReceiptsData) else { return nil }
        let receiptBinary = regeneratedParentState.root.artifact?.children.elements().map { $0.1.artifact?.scalar }
        guard let allReceiptBinary = receiptBinary else { return nil }
        return allReceiptBinary.reduce([], { (result, entry) -> [ReceiptType]? in
            guard let result = result else { return nil }
            guard let entry = entry else { return nil }
            guard let receiptAction = ActionType(data: entry) else { return nil }
            guard let receipt = ReceiptType(action: receiptAction) else { return nil }
            return result + [receipt]
        })
    }
    
    func extractActions() -> [ActionType]? {
        let actions = actionsRoot.artifact?.children.elements().map { $0.1.artifact?.scalar }
        guard let allActions = actions else { return nil }
        return allActions.reduce([]) { (result, entry) -> [ActionType]? in
            guard let result = result else { return nil }
            guard let entry = entry else { return nil }
            if !entry.verify() { return nil }
            return result + [entry]
        }
    }
    
    static func extractSigners(publicKeys: [Data]) -> Set<Digest>? {
       return publicKeys.reduce(Set<Digest>()) { (result, entry) -> Set<Digest>? in
            guard let result = result else { return nil }
            guard let pkDigestBinary = CryptoDelegateType.hash(entry) else { return nil }
            guard let pkDigest = Digest(data: pkDigestBinary) else { return nil }
            return result.union([pkDigest])
        }
    }
    
    func extractPublicKeys() -> [Data]? {
        let publicKeys = publicKeysRoot.artifact?.children.elements().map { $0.1.artifact?.scalar }
        guard let allPublicKeys = publicKeys else { return nil }
        return allPublicKeys.reduce([]) { (result, entry) -> [Data]? in
            guard let result = result else { return nil }
            guard let entry = entry else { return nil }
            return result + [entry]
        }
    }
    
    func extractSignatures() -> [Data]? {
        let signatures = signaturesRoot.artifact?.children.elements().map { $0.1.artifact?.scalar }
        guard let allSignatures = signatures else { return nil }
        return allSignatures.reduce([]) { (result, entry) -> [Data]? in
            guard let result = result else { return nil }
            guard let entry = entry else { return nil }
            return result + [entry]
        }
    }
    
    static func extractHomesteadRoot(homestead: StateObject, actions: [ActionType]) -> DataArrayAddress? {
        guard let fullCore = homestead.root.artifact?.core else { return nil }
        let emptyCore = fullCore.empty()
        let coreAfterActions = actions.reduce(emptyCore) { (result, entry) -> State.CoreType? in
            guard let result = result else { return nil }
            guard let transitionProof = fullCore.transitionProof(proofType: entry.proofType(), for: entry.key) else { return nil }
            return result.merging(transitionProof)
        }
        guard let finalCore = coreAfterActions else { return nil }
        return convert(allBinaries: finalCore.contents().values())
    }
    
    static func extractParentReceiptsRoot(parentHomestead: StateObject, parentReceipts: [ReceiptType]) -> DataArrayAddress? {
        let receiptActions = parentReceipts.map { $0.toAction() }
        if receiptActions.contains(where: { $0.new == nil }) { return nil }
        let parentScalars = receiptActions.map { DataScalar(scalar: $0.new!) }
        let parentKeysBinaries = parentReceipts.map { $0.toAction().key }
        let parentKeyStrings = parentKeysBinaries.reduce([]) { (result, entry) -> [String]? in
            guard let result = result else { return nil }
            return result + [entry]
        }
        guard let parentKeys = parentKeyStrings else { return nil }
        guard let fullParent = parentHomestead.root.artifact?.core else { return nil }
        let emptyParent = fullParent.empty()
        let merged = parentKeys.reduce(emptyParent) { (result, entry) -> State.CoreType? in
            guard let result = result else { return nil }
            guard let transitionProof = fullParent.transitionProof(proofType: .mutation, for: entry) else { return nil }
            return result.merging(transitionProof)
        }
        guard let targetedParentKeys = merged else { return nil }
        let information = parentScalars.map { $0.toData() } + targetedParentKeys.contents().values()
        return convert(allBinaries: information)
    }
}
