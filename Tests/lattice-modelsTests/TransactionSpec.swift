import Foundation
import Nimble
import Quick
import AwesomeDictionary
import AwesomeTrie
import Regenerate
@testable import lattice_models

final class TransactionSpec: QuickSpec {
    override func spec() {
        describe("Transaction") {
            typealias TransactionObject = RGObject<TransactionAddress>
            typealias TransactionAddress = Address<TransactionArtifactType>
            typealias TransactionArtifactType = TransactionArtifactImpl
            typealias ActionType = TransactionArtifactType.ActionType
            typealias StateObject = TransactionArtifactType.StateObject
            typealias StateAddress = TransactionArtifactType.StateAddress
            typealias State = TransactionArtifactType.State
            typealias BinaryAddress = State.Value
            typealias BinaryScalar = BinaryAddress.Artifact
            typealias Digest = TransactionArtifactType.Digest
            typealias AccountType = TransactionArtifactType.AccountType
            typealias ReceiptType = TransactionArtifactType.ReceiptType
            typealias DemandType = ReceiptType.DemandType
            typealias DepositType = TransactionArtifactType.DepositType
            typealias PeerType = TransactionArtifactType.PeerType
            typealias SendableType = PeerType.SendableType
            typealias CryptoDelegate = TransactionArtifactType.CryptoDelegateType
            
            let fee = Digest(0)
            let addressBinary = CryptoDelegate.hash(publicKey.toBoolArray())!
            let addressDigest = Digest(raw: addressBinary)!
            let homesteadState = State(da: [:])!
            let homesteadStateRoot = StateAddress(artifact: homesteadState, complete: true)!
            let homesteadStateObject = StateObject(root: homesteadStateRoot)
            let publicKeySignatures = TrieMapping<Bool, [Bool]>()
            let feeAction = AccountType(address: addressDigest, oldBalance: Digest(0), newBalance: Digest(1))
            let transactionArtifact = TransactionArtifactType(actions: [feeAction.toAction()], fee: fee, previousHash: nil, publicKeySignatures: publicKeySignatures, homesteadState: homesteadStateObject, parentHomesteadState: nil, parentReceipts: [], publicKey: publicKey.toBoolArray(), privateKey: privateKey.toBoolArray())
            let convertedTransaction = transactionArtifact!.convertToTransaction()
            it("should not be nil") {
                expect(homesteadState).toNot(beNil())
                expect(transactionArtifact).toNot(beNil())
                expect(transactionArtifact!.convertToTransaction()).toNot(beNil())
            }
            it("should verify") {
                expect(convertedTransaction!.verifyAll(filters: [])).to(beTrue())
            }
            describe("Every transaction that have a fee that is paid") {
                let transactionArtifact = TransactionArtifactType(actions: [feeAction.toAction()], fee: Digest(1), previousHash: nil, publicKeySignatures: publicKeySignatures, homesteadState: homesteadStateObject, parentHomesteadState: nil, parentReceipts: [], publicKey: publicKey.toBoolArray(), privateKey: privateKey.toBoolArray())
                let convertedTransaction = transactionArtifact!.convertToTransaction()
                it("should reject transactions with non valid fees") {
                    expect(convertedTransaction).toNot(beNil())
                    expect(convertedTransaction!.verifyAll(filters: [])).to(beFalse())
                }
            }
            describe("Every transaction should have valid signatures") {
                it("should reject transactions with invalid signatures") {
                    let realSignature = convertedTransaction!.signatures.elements().first!
                    let fakeSignature = convertedTransaction!.signatures.setting(keys: realSignature.0, value: realSignature.1 + [true])
                    let fakeSigTransaction = TransactionArtifactType.TransactionType(unreservedActions: convertedTransaction!.unreservedActions, accountActions: convertedTransaction!.accountActions, receiptActions: convertedTransaction!.receiptActions, depositActions: convertedTransaction!.depositActions, genesisActions: convertedTransaction!.genesisActions, seedActions: convertedTransaction!.seedActions, peerActions: convertedTransaction!.peerActions, parentReceipts: convertedTransaction!.parentReceipts, signers: convertedTransaction!.signers, signatures: fakeSignature, fee: convertedTransaction!.fee, parentHomesteadRoot: convertedTransaction!.parentHomesteadRoot, transactionHash: convertedTransaction!.transactionHash, stateDelta: convertedTransaction!.stateDelta, stateData: convertedTransaction!.stateData)
                    expect(fakeSigTransaction.verifyAll(filters: [])).to(beFalse())
                }
            }
            describe("Every transaction containing account funds being spent needs to be signed by account owner") {
                let transactionWithFundsSigned = convertedTransaction!.changing(accountActions: [AccountType(address: addressDigest, oldBalance: Digest(1), newBalance: Digest(0))])
                let transactionWithFundsNotSigned = convertedTransaction!.changing(accountActions: [AccountType(address: addressDigest + Digest(1), oldBalance: Digest(1), newBalance: Digest(0))])
                it("should reject transaction with funds not signed and vice versa") {
                    expect(transactionWithFundsSigned.verifyAll(filters: [])).to(beTrue())
                    expect(transactionWithFundsNotSigned.verifyAll(filters: [])).to(beFalse())
                }
            }
            describe("Every receipt needs to pay receipt demand") {
                let sender = Digest(10)
                let demander = addressDigest
                let receipt = ReceiptType(sender: sender, demand: DemandType(nonce: Digest(10), recipient: demander, amount: Digest(2)))
                let transactionWithoutReceiptPaid = convertedTransaction!.changing(receiptActions: [receipt])
                let transacstionWithReceiptPaid = transactionWithoutReceiptPaid.changing(accountActions: [AccountType(address: demander, oldBalance: Digest(0), newBalance: Digest(2))])
                it("should reject transaction without receipts paid") {
                    expect(transactionWithoutReceiptPaid.verifyAll(filters: [])).to(beFalse())
                    expect(transacstionWithReceiptPaid.verifyAll(filters: [])).to(beTrue())
                }
            }
            describe("Every transaction drawing from a deposit source must have corresponding parent receipt with matching demand") {
                let receiptSender = addressDigest
                let demand = DemandType(nonce: Digest(0), recipient: Digest(1), amount: Digest(2))
                let receipt = ReceiptType(sender: receiptSender, demand: demand)
                let deposit = DepositType(demand: demand, oldBalance: 10, newBalance: 5)
                let transactionWithDepositWithoutParentReceipts = convertedTransaction!.changing(depositActions: [deposit])
                let transactionWithDepositWithParentReceipts = transactionWithDepositWithoutParentReceipts.changing(parentReceipts: [receipt])
                it("should reject transaction with deposit") {
                    expect(transactionWithDepositWithoutParentReceipts.verifyAll(filters: [])).to(beFalse())
                    expect(transactionWithDepositWithParentReceipts.verifyAll(filters: [])).to(beTrue())
                }
            }
            describe("Every transaction containing parent receipts must be signed by signed by the senders of the receipts") {
                let demand = DemandType(nonce: Digest(0), recipient: Digest(1), amount: Digest(2))
                let validReceipt = ReceiptType(sender: addressDigest, demand: demand)
                let invalidReceipt = ReceiptType(sender: addressDigest + Digest(1), demand: demand)
                let transactionWithReceiptNotSigned = convertedTransaction!.changing(parentReceipts: [invalidReceipt])
                let transactionWithReceiptSigned = convertedTransaction!.changing(parentReceipts: [validReceipt])
                it("should reject transation with a parent receipt not signed") {
                    expect(transactionWithReceiptNotSigned.verifyAll(filters: [])).to(beFalse())
                    expect(transactionWithReceiptSigned.verifyAll(filters: [])).to(beTrue())
                }
            }
            describe("Every transaction containing peer changes must be signed by those peers") {
                let sendable = SendableType(ip: "192.168.1.1", port: 88)
                let validPeer = PeerType(address: addressDigest, old: nil, new: sendable)
                let invalidPeer = PeerType(address: addressDigest + Digest(1), old: nil, new: sendable)
                let transactionWithPeerNotSigned = convertedTransaction!.changing(peerActions: [invalidPeer])
                let transactionWithPeerSigned = convertedTransaction!.changing(peerActions: [validPeer])
                it("should reject transactions without a peer not signed") {
                    expect(transactionWithPeerNotSigned.verifyAll(filters: [])).to(beFalse())
                    expect(transactionWithPeerSigned.verifyAll(filters: [])).to(beTrue())
                }
            }
            describe("Transactions need to pass filters") {
                let passingRule = "var transactionFilter = function(value) { return true; }"
                let failingRule = "var transactionFilter = function(value) { return false; }"
                it("should reject transactions that do not pass filters") {
                    expect(convertedTransaction!.verifyAll(filters: [passingRule])).to(beTrue())
                    expect(convertedTransaction!.verifyAll(filters: [failingRule])).to(beFalse())
                }
            }
        }
    }
}

let privateKey = """
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAlznyd/pK9bVqC8JUv8q3SN8yCuk1vagIyHgF0MJPPIlU5fpX
HyUKN60IaIjD4ujjHu0mDnmJo9rh4gkXlfymIWl5gAD1tQ6K4u9TwIOB7oowBKYG
1xHNYBHZxP3pj/7rgKkQEvBZUrdBi4ss9wVvqjFK0wz7GiN8F2uxvR0foeqT/RV/
HZoglhVmj2FwC2hHIQFCrOgmzmbtEEyvC+h9DaSr7h5d6UM5Konqktq6OaZCALbo
IriaQnTjcyexcpSENLnPFMiNdUiOTQyXOKEI+ar59AdIpmEespwlQDFMka0MoxsX
vr4tRmeyl49En0EqYYRH5AIeeblkHfPh/fiBXwIDAQABAoIBAAzJLHPyaIYPuZCW
9J1moUp6/Hspro6Dd4KjizJUS2i937y2BsmuUwfUDGLyNUWpFRLXUCFnKzj8V57J
0AGxY8ZtaYVmD2Aog5ueSoF7XO/zJQ4vj2J9sdSOjc/2+9ld30F4idBgG90/ez42
HS4heoh0NHRVo6FZILPGOjfYD4Wb83L0gai+5kkhecDg8UWtVSzYbIyhB7G7SeWW
ogyQrugQbptB6TYTnoPsmraouU2aVEMOhC5sHLk3s7YGKce1UWJB95SUBSNE3itr
ljLkYBP42gjEzvc0sfNrXuxRXiQyrD+Go5lptsWE7aBpJk9nsXFsN1Kl6FqBTn+s
eFJSC1kCgYEAx1/AVsY2Isc96go9Owfz+PTrR8/PaWbcrjZLMmq5G7f0rTCRjUc9
MhYu2AiD1khauZD3TBsspO6WKALAJJlsv2GCuBCo42tUNz1JWystIYcfe64u3zaz
HVWV3H6mwfoND4EMoT0cytwadpf6629ql/b0o/vRwXAjxP2LTDnuIu0CgYEAwi1v
jmNI3raY46uv6X4LQEHpSQiLiNazVd2J724ZXeGdZCqDsRQCZYkZqyFZtd1yEiTd
6Ah1CS3H3a/MUt80AgPNb4MaRZWetZNavtNZ/JdqpN5FFsgrnmU7xOmhV+4HjQpE
pqU8qFpUey+L6A+iyZ8D2P+OVhaVKM5+2qlF7/sCgYA/x2S7HZtR0tT+mpnt2WR1
nrvpdBQQzsQHwvyZO0TOFjHieWgGfuSXsjr4BvlNwkWrmTFTGlpUxLIqSH749k+w
hVwQz9uHLN168lMWJCDC2fv7T8RUyaXQ24EeUTG9WeV1sT2+EtO0HWclywaM7E54
IJswHi2CqQH4UXePQfTpHQKBgQC284BMNBeQX5Kl0DmqUWvgWzml6jst7ryBhn5T
7PRRlCVrHvN9gFDRwd9BcebIh6DWn43E9VLwFwZdRSnKWyrxSwvgqTGzpkkm43N4
oEIEz9VXCWUnFeqjDtbFrSqrYkYTCT2tlboVFSbL+fxj5XeHaB+D8ST2z8gx7n1v
IFYYyQKBgClVy+MWDCJPMm2dRk6AEKGdAs4yiO5Sb710t29kvxKtZzUuyFCRZAtt
ENIcr0ZvAo6rQwP+DgsvYdKeUQbQaKDR82HkT/SUNPergdp5SFaR2C2XpRyYHh5q
Xj9uKUw0ExH06Qa5GGAcVhcw0PyGtM09Mu93iQbMUukBqQGQN5Z3
-----END RSA PRIVATE KEY-----
"""

let publicKey = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlznyd/pK9bVqC8JUv8q3
SN8yCuk1vagIyHgF0MJPPIlU5fpXHyUKN60IaIjD4ujjHu0mDnmJo9rh4gkXlfym
IWl5gAD1tQ6K4u9TwIOB7oowBKYG1xHNYBHZxP3pj/7rgKkQEvBZUrdBi4ss9wVv
qjFK0wz7GiN8F2uxvR0foeqT/RV/HZoglhVmj2FwC2hHIQFCrOgmzmbtEEyvC+h9
DaSr7h5d6UM5Konqktq6OaZCALboIriaQnTjcyexcpSENLnPFMiNdUiOTQyXOKEI
+ar59AdIpmEespwlQDFMka0MoxsXvr4tRmeyl49En0EqYYRH5AIeeblkHfPh/fiB
XwIDAQAB
-----END PUBLIC KEY-----
"""
