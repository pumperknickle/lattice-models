import Foundation
import Regenerate
import Bedrock
import CryptoStarterPack

public struct TransactionArtifactImpl: Codable {
    private let rawActionsRoot: ActionArrayAddress!
    private let rawFee: Digest!
    private let rawPreviousHash: Digest?
    private let rawPublicKeysRoot: DataArrayAddress!
    private let rawSignaturesRoot: DataArrayAddress!
    private let rawHomesteadRoot: Digest!
    private let rawHomesteadDataRoot: DataArrayAddress!
    private let rawParentHomesteadRoot: Digest?
    private let rawParentReceiptRoot: DataArrayAddress!
    
    public init(actionsRoot: ActionArrayAddress, fee: UInt256, previousHash: UInt256?, publicKeysRoot: DataArrayAddress, signaturesRoot: DataArrayAddress, homesteadRoot: UInt256, homesteadDataRoot: DataArrayAddress, parentHomesteadRoot: UInt256?, parentReceiptRoot: DataArrayAddress) {
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
    public typealias DataScalar = Scalar<Data>
    public typealias DataAddress = Address<DataScalar>
    public typealias DataArray = Array256<DataAddress>
    public typealias DataArrayAddress = Address<DataArray>
    public typealias State = Dictionary256<String, DataAddress>
    public typealias StateAddress = Address<State>
    public typealias StateObject = RGObject<StateAddress>
    
    public var actionsRoot: ActionArrayAddress! { return rawActionsRoot }
    public var fee: Digest! { return rawFee }
    public var previousHash: Digest? { return rawPreviousHash }
    public var publicKeysRoot: DataArrayAddress! { return rawPublicKeysRoot }
    public var signaturesRoot: DataArrayAddress! { return rawSignaturesRoot }
    public var homesteadRoot: Digest! { return rawHomesteadRoot }
    public var homesteadDataRoot: DataArrayAddress! { return rawHomesteadDataRoot }
    public var parentHomesteadRoot: Digest? { return rawParentHomesteadRoot }
    public var parentReceiptRoot: DataArrayAddress! { return rawParentReceiptRoot }
}
