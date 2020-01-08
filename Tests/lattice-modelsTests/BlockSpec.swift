import Foundation
import Nimble
import Quick
import AwesomeDictionary
import AwesomeTrie
import Regenerate
@testable import lattice_models

final class BlockSpec: QuickSpec {
    override func spec() {
        describe("Blocks with No Children") {
            // define block types
            typealias BlockArtifactType = BlockArtifactImpl
            typealias BlockType = BlockArtifactType.BlockType
            typealias BlockAddressType = BlockArtifactType.BlockAddress
            typealias BlockDictionaryType = BlockArtifactType.BlockDictionary
            typealias BlockDictionaryAddressType = BlockArtifactType.BlockDictionaryAddress
            typealias DefinitionArtifactType = BlockArtifactType.DefinitionArtifactType
            typealias CryptoDelegate = TransactionArtifactType.CryptoDelegateType

            // define transaction types
            typealias TransactionArtifactType = BlockArtifactType.TransactionArtifactType
            typealias ActionType = TransactionArtifactType.ActionType
            typealias StateObject = TransactionArtifactType.StateObject
            typealias StateAddress = TransactionArtifactType.StateAddress
            typealias State = TransactionArtifactType.State
            typealias DataAddress = TransactionArtifactType.DataAddress
            typealias DataScalar = TransactionArtifactType.DataScalar
            typealias AccountType = TransactionArtifactType.AccountType
            typealias PeerType = TransactionArtifactType.PeerType
            typealias SendableType = PeerType.SendableType
            
            typealias Digest = TransactionArtifactType.Digest
            
            // define chain metadata definition
            let definition = DefinitionArtifactType(size: Digest(1000000), premine: Digest(1000000000000000000), period: Double(10), initialRewardExponent: 10, filters: ["var transactionFilter = function(value) { return true; }"])
            let convertedDefinition = definition?.toDefinition()

            // define user
            let addressBinary = CryptoDelegate.hash(publicKey.toData())!
            let addressDigest = Digest(data: addressBinary)!
            
            // define homestead state in block 0
            let homesteadState0: State = State(da: [:])!
            
            // define transactions in block 0
            let accountAction = AccountType(address: addressDigest, oldBalance: Digest(0), newBalance: Digest(10))
            let homesteadStateRoot0 = StateAddress(artifact: homesteadState0, complete: true)!
            let homesteadStateObject0 = StateObject(root: homesteadStateRoot0)
            let transactionArtifact0 = TransactionArtifactType(actions: [accountAction.toAction()], fee: Digest(0), previousHash: nil, publicKeySignatures: Mapping<Data, Data>(), homesteadState: homesteadStateObject0, parentHomesteadState: nil, parentReceipts: [], publicKey: publicKey.toData(), privateKey: privateKey.toData())
            
            // define genesis block artifact
            let genesisBlock = BlockArtifactType(transactionArtifacts: [transactionArtifact0!], definitionArtifact: definition!, nextDifficulty: Digest.max, index: Digest(0), timestamp: Double(1000), previousBlock: nil, homestead: homesteadState0.core.digest, parent: nil, nonce: Digest(0), children: [:])
            let genesisAddress = BlockAddressType(artifact: genesisBlock!, complete: true)

            // define homestead state in block 1
            let key1 = ACCOUNT_PREFIX + addressDigest.toString()
            let value1 = Digest(10).toData()
            let scalar1 = DataScalar(scalar: value1)
            let dict: [String: DataScalar?] = [key1: scalar1]
            let homesteadState1: State = State(da: dict)!

            // define transactions in block 1
            let fee = Digest(1)
            let feeAction = AccountType(address: addressDigest, oldBalance: Digest(10), newBalance: Digest(9))
            let homesteadStateRoot1 = StateAddress(artifact: homesteadState1, complete: true)!
            let homesteadStateObject1 = StateObject(root: homesteadStateRoot1)
            let transactionArtifact1 = TransactionArtifactType(actions: [feeAction.toAction()], fee: fee, previousHash: genesisAddress!.digest, publicKeySignatures: Mapping<Data, Data>(), homesteadState: homesteadStateObject1, parentHomesteadState: nil, parentReceipts: [], publicKey: publicKey.toData(), privateKey: privateKey.toData())
            
            // define block 1
            let blockArtifact1 = BlockArtifactType(transactionArtifacts: [transactionArtifact1!], definitionArtifact: definition!, nextDifficulty: Digest(10), index: Digest(1), timestamp: Double(1001), previousBlock: genesisBlock!, homestead: homesteadState1.core.root.digest, parent: nil, nonce: Digest(1), children: [:])
            let convertedBlock = blockArtifact1!.toBlock()
            
            it("should create the definition and transaction succesfully") {
                expect(transactionArtifact1).toNot(beNil())
                expect(convertedDefinition).toNot(beNil())
                expect(convertedBlock).toNot(beNil())
                expect(convertedBlock!.verifyAll()).to(beTrue())
            }
            
            describe("Blocks cannot add more currency than reward") {
                let fee = Digest(0)
                let reward = convertedDefinition!.rewardAtBlock(index: 1)
                let invalidAction = AccountType(address: addressDigest, oldBalance: Digest(10), newBalance: Digest(10) + reward + Digest(1))
                let invalidTransactionArtifact = TransactionArtifactType(actions: [invalidAction.toAction()], fee: fee, previousHash: genesisAddress!.digest, publicKeySignatures: Mapping<Data, Data>(), homesteadState: homesteadStateObject1, parentHomesteadState: nil, parentReceipts: [], publicKey: publicKey.toData(), privateKey: privateKey.toData())
                let invalidBlockArtifact = BlockArtifactType(transactionArtifacts: [invalidTransactionArtifact!], definitionArtifact: definition!, nextDifficulty: Digest(10), index: Digest(1), timestamp: Double(1001), previousBlock: genesisBlock!, homestead: homesteadState1.core.root.digest, parent: nil, nonce: Digest(1), children: [:])
                let invalidBlock = invalidBlockArtifact!.toBlock()
                let validAction = AccountType(address: addressDigest, oldBalance: Digest(10), newBalance: Digest(10) + reward)
                let validTransactionArtifact = TransactionArtifactType(actions: [validAction.toAction()], fee: fee, previousHash: genesisAddress!.digest, publicKeySignatures: Mapping<Data, Data>(), homesteadState: homesteadStateObject1, parentHomesteadState: nil, parentReceipts: [], publicKey: publicKey.toData(), privateKey: privateKey.toData())
                let validBlockArtifact = BlockArtifactType(transactionArtifacts: [validTransactionArtifact!], definitionArtifact: definition!, nextDifficulty: Digest(10), index: Digest(1), timestamp: Double(1001), previousBlock: genesisBlock!, homestead: homesteadState1.core.root.digest, parent: nil, nonce: Digest(1), children: [:])
                let validBlock = validBlockArtifact!.toBlock()
                it("should not verify if blocks add more currency than reward") {
                    expect(reward).to(equal(Digest(Int(pow(Double(2), Double(10))))))
                    expect(invalidBlock).toNot(beNil())
                    expect(invalidBlock!.verifyAll()).to(beFalse())
                    expect(validBlock).toNot(beNil())
                    expect(validBlock!.verifyAll()).to(beTrue())
                }
            }
            
            describe("Block transactions should match previous hash") {
                let homesteadStateRoot1 = StateAddress(artifact: homesteadState1, complete: true)!
                let homesteadStateObject1 = StateObject(root: homesteadStateRoot1)
                let invalidTransactionArtifact = TransactionArtifactType(actions: [feeAction.toAction()], fee: fee, previousHash: nil, publicKeySignatures: Mapping<Data, Data>(), homesteadState: homesteadStateObject1, parentHomesteadState: nil, parentReceipts: [], publicKey: publicKey.toData(), privateKey: privateKey.toData())
                // define block 1
                let invalidBlockArtifact = BlockArtifactType(transactionArtifacts: [invalidTransactionArtifact!], definitionArtifact: definition!, nextDifficulty: Digest(10), index: Digest(1), timestamp: Double(1001), previousBlock: genesisBlock!, homestead: homesteadState1.core.root.digest, parent: nil, nonce: Digest(1), children: [:])
                let invalidBlock = invalidBlockArtifact!.toBlock()
                it("should not verify") {
                    expect(invalidBlock).toNot(beNil())
                    expect(invalidBlock!.verifyAll()).to(beFalse())
                }
            }
            
            describe("new difficulty must be set correctly") {
                let invalidBlockArtifact = BlockArtifactType(transactionArtifacts: [transactionArtifact1!], definitionArtifact: definition!, nextDifficulty: Digest.max, index: Digest(1), timestamp: Double(1009), previousBlock: genesisBlock!, homestead: homesteadState1.core.root.digest, parent: nil, nonce: Digest(1), children: [:])
                let invalidBlock = invalidBlockArtifact!.toBlock()
                let validBlockArtifact = BlockArtifactType(transactionArtifacts: [transactionArtifact1!], definitionArtifact: definition!, nextDifficulty: Digest.max, index: Digest(1), timestamp: Double(1010), previousBlock: genesisBlock!, homestead: homesteadState1.core.root.digest, parent: nil, nonce: Digest(1), children: [:])
                let validBlock = validBlockArtifact!.toBlock()
                it("should not verify if difficulty is not set correctly") {
                    expect(invalidBlock).toNot(beNil())
                    expect(invalidBlock!.verifyAll()).to(beFalse())
                    expect(validBlock).toNot(beNil())
                    expect(validBlock!.verifyAll()).to(beTrue())
                }
            }
            
            describe("transaction must verify for block to verify") {
                let definition = DefinitionArtifactType(size: Digest(1000000), premine: Digest(1000000000000000000), period: Double(10), initialRewardExponent: 10, filters: ["var transactionFilter = function(value) { return false; }"])
                let invalidGenesisBlock = BlockArtifactType(transactionArtifacts: [transactionArtifact0!], definitionArtifact: definition!, nextDifficulty: Digest.max, index: Digest(0), timestamp: Double(1000), previousBlock: nil, homestead: homesteadState0.core.digest, parent: nil, nonce: Digest(0), children: [:])
                let blockArtifact1 = BlockArtifactType(transactionArtifacts: [transactionArtifact1!], definitionArtifact: definition!, nextDifficulty: Digest(10), index: Digest(1), timestamp: Double(1001), previousBlock: invalidGenesisBlock!, homestead: homesteadState1.core.root.digest, parent: nil, nonce: Digest(1), children: [:])
                let invalidBlock = blockArtifact1!.toBlock()
                it("should not verify if tranasctions do not verify") {
                    expect(invalidBlock).toNot(beNil())
                    expect(invalidBlock!.verifyAll()).to(beFalse())
                }
            }
            
            describe("block can't have a differing definition than previous block") {
                let invalidDefinition = DefinitionArtifactType(size: Digest(100000), premine: Digest(1000000000000000000), period: Double(10), initialRewardExponent: 10, filters: ["var transactionFilter = function(value) { return false; }"])
                let invalidBlockArtifact = BlockArtifactType(transactionArtifacts: [transactionArtifact1!], definitionArtifact: invalidDefinition!, nextDifficulty: Digest(10), index: Digest(1), timestamp: Double(1001), previousBlock: genesisBlock!, homestead: homesteadState1.core.root.digest, parent: nil, nonce: Digest(1), children: [:])
                let invalidBlock = invalidBlockArtifact?.toBlock()
                it("should not verify if definition hash differs from previous") {
                    expect(invalidBlock).toNot(beNil())
                    expect(invalidBlock!.verifyAll()).to(beFalse())
                }
            }
            
            describe("block transaction deltas must be under size limit stated in definition") {
                let invalidDefinition = DefinitionArtifactType(size: Digest(10), premine: Digest(1000000000000000000), period: Double(10), initialRewardExponent: 10, filters: ["var transactionFilter = function(value) { return true; }"])
                let sendable = SendableType(ip: "192.1.1.1", port: 10)
                let peerAction = PeerType(address: addressDigest, old: nil, new: sendable)
                let transactionArtifact1 = TransactionArtifactType(actions: [feeAction.toAction(), peerAction.toAction()], fee: fee, previousHash: genesisAddress!.digest, publicKeySignatures: Mapping<Data, Data>(), homesteadState: homesteadStateObject1, parentHomesteadState: nil, parentReceipts: [], publicKey: publicKey.toData(), privateKey: privateKey.toData())
                let invalidBlockArtifact = BlockArtifactType(transactionArtifacts: [transactionArtifact1!], definitionArtifact: invalidDefinition!, nextDifficulty: Digest(10), index: Digest(1), timestamp: Double(1001), previousBlock: genesisBlock!, homestead: homesteadState1.core.root.digest, parent: nil, nonce: Digest(1), children: [:])
                let invalidBlock = invalidBlockArtifact?.toBlock()
                
                let validBlockArtifact = BlockArtifactType(transactionArtifacts: [transactionArtifact1!], definitionArtifact: definition!, nextDifficulty: Digest(10), index: Digest(1), timestamp: Double(1001), previousBlock: genesisBlock!, homestead: homesteadState1.core.root.digest, parent: nil, nonce: Digest(1), children: [:])
                let validBlock = validBlockArtifact?.toBlock()

                it("should not verify if oversized") {
                    expect(validBlock).toNot(beNil())
                    expect(validBlock!.verifyAll()).to(beTrue())
                    expect(invalidBlock).toNot(beNil())
                    expect(invalidBlock!.verifyAll()).to(beFalse())
                }
            }
        }
    }
}
