import Foundation
import Regenerate
import Bedrock
import CryptoStarterPack

public struct TransactionArtifactImpl: Codable {
    private let rawActionsRoot: ActionArrayAddress!
    private let rawFee: Digest!
    private let rawPreviousHash: Digest?
    private let rawPublicKeysRoot: BinaryArrayAddress!
    private let rawSignaturesRoot: BinaryArrayAddress!
    private let rawHomesteadRoot: Digest!
    private let rawHomesteadDataRoot: BinaryArrayAddress!
    private let rawParentHomesteadRoot: Digest?
    private let rawParentReceiptRoot: BinaryArrayAddress!
    
    public init(actionsRoot: Address<TransactionArtifactImpl.ActionArray>, fee: UInt256, previousHash: UInt256?, publicKeysRoot: Address<TransactionArtifactImpl.BinaryArray>, signaturesRoot: Address<TransactionArtifactImpl.BinaryArray>, homesteadRoot: UInt256, homesteadDataRoot: Address<TransactionArtifactImpl.BinaryArray>, parentHomesteadRoot: UInt256?, parentReceiptRoot: Address<TransactionArtifactImpl.BinaryArray>) {
        rawActionsRoot = actionsRoot
        rawFee = fee
        rawPreviousHash = previousHash
        rawPublicKeysRoot = publicKeysRoot
        rawSignaturesRoot = signaturesRoot
        rawHomesteadRoot = homesteadRoot
        rawHomesteadDataRoot = homesteadDataRoot
        rawParentHomesteadRoot = parentHomesteadRoot
        rawParentReceiptRoot = parentReceiptRoot
    }
}

extension TransactionArtifactImpl: TransactionArtifact {
    public typealias Digest = UInt256
    public typealias AsymmetricDelegateType = BaseAsymmetric
    public typealias CryptoDelegateType = BaseCrypto
    public typealias TransactionType = TransactionImpl
    public typealias ActionType = ActionImpl
    public typealias ActionScalar = Scalar<ActionImpl>
    public typealias ActionAddress = Address<ActionScalar>
    public typealias ActionArray = Array256<ActionAddress>
    public typealias ActionArrayAddress = Address<ActionArray>
    public typealias BinaryScalar = Scalar<[Bool]>
    public typealias BinaryAddress = Address<BinaryScalar>
    public typealias BinaryArray = Array256<BinaryAddress>
    public typealias BinaryArrayAddress = Address<BinaryArray>
    public typealias State = Dictionary256<String, BinaryAddress>
    public typealias StateAddress = Address<State>
    public typealias StateObject = RGObject<StateAddress>
    
    public var actionsRoot: ActionArrayAddress! { return rawActionsRoot }
    public var fee: Digest! { return rawFee }
    public var previousHash: Digest? { return rawPreviousHash }
    public var publicKeysRoot: BinaryArrayAddress! { return rawPublicKeysRoot }
    public var signaturesRoot: BinaryArrayAddress! { return rawSignaturesRoot }
    public var homesteadRoot: Digest! { return rawHomesteadRoot }
    public var homesteadDataRoot: BinaryArrayAddress! { return rawHomesteadDataRoot }
    public var parentHomesteadRoot: Digest? { return rawParentHomesteadRoot }
    public var parentReceiptRoot: BinaryArrayAddress! { return rawParentReceiptRoot }
}
