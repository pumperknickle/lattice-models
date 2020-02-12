import Foundation
import Nimble
import Quick
import AwesomeDictionary
import AwesomeTrie
import Regenerate
@testable import lattice_models

final class GenesisBlockSpec: QuickSpec {
    override func spec() {
        // define block types
        typealias BlockArtifactType = BlockArtifactImpl
        typealias BlockType = BlockArtifactType.BlockType
        typealias BlockAddressType = BlockArtifactType.BlockAddress
        typealias BlockDictionaryType = BlockArtifactType.BlockDictionary
        typealias BlockDictionaryAddressType = BlockArtifactType.BlockDictionaryAddress
        typealias DefinitionArtifactType = BlockArtifactType.DefinitionArtifactType
        typealias CryptoDelegate = TransactionArtifactType.CryptoDelegateType
        
        typealias TransactionArtifactType = BlockArtifactType.TransactionArtifactType
        typealias ActionType = TransactionArtifactType.ActionType
        typealias StateObject = TransactionArtifactType.StateObject
        typealias StateAddress = TransactionArtifactType.StateAddress
        typealias State = TransactionArtifactType.State
        typealias AccountType = TransactionArtifactType.AccountType

        typealias Digest = TransactionArtifactType.Digest
        
        let definition = DefinitionArtifactType(size: Digest(1000000), premine: Digest(1000000000000000000), period: Double(10), initialRewardExponent: 10, filters: ["var transactionFilter = function(value) { return true; }"])
        let def = definition!.toDefinition()!

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
        let genesisArtifact = BlockArtifactType(transactionArtifacts: [transactionArtifact0!], definitionArtifact: definition!, nextDifficulty: Digest.max, index: Digest(0), timestamp: Double(1000), previousBlock: nil, homestead: homesteadState0.core.digest, parent: nil, nonce: Digest(0), children: [:])
        let genesisBlock = genesisArtifact!.toGenesis()
        describe("control state") {
            it("should succeed as control state") {
                expect(genesisBlock).toNot(beNil())
                expect(genesisBlock!.verifyAllForGenesis()).to(beTrue())
            }
        }
        
        describe("genesis may not have children") {
            it("should not verify if it contains children") {
                let invalidGenesisBlock = genesisBlock!.changing(children: Mapping<String, BlockType>().setting(key: "hello", value: genesisBlock!))
                expect(invalidGenesisBlock.verifyAllForGenesis()).to(beFalse())
            }
        }
        
        describe("genesis may not contain other genesis") {
            it("should not verify if it contains other genesis") {
                let invalidGenesisBlock = genesisBlock!.changing(genesis: Mapping<String, BlockType>().setting(key: "hello", value: genesisBlock!))
                expect(invalidGenesisBlock.verifyAllForGenesis()).to(beFalse())
            }
        }
        
        describe("genesis must have index equal to 0") {
            it("should fail because index is not 0") {
                let invalidGenesisBlock = genesisBlock!.changing(index: Digest(1))
                expect(invalidGenesisBlock.verifyAllForGenesis()).to(beFalse())
            }
        }        

        describe("genesis block must not take more than premine") {
            let totalPremine = def.premineAmount() + def.rewardAtBlock(index: Digest(0))
            let invalidAccountAction = AccountType(address: addressDigest, oldBalance: Digest(0), newBalance: totalPremine.advanced(by: 1))
            let invalidTransactionArtifact0 = TransactionArtifactType(actions: [invalidAccountAction.toAction()], fee: Digest(0), previousHash: nil, publicKeySignatures: Mapping<Data, Data>(), homesteadState: homesteadStateObject0, parentHomesteadState: nil, parentReceipts: [], publicKey: publicKey.toData(), privateKey: privateKey.toData())
            let invalidGenesisArtifact = BlockArtifactType(transactionArtifacts: [invalidTransactionArtifact0!], definitionArtifact: definition!, nextDifficulty: Digest.max, index: Digest(0), timestamp: Double(1000), previousBlock: nil, homestead: homesteadState0.core.digest, parent: nil, nonce: Digest(0), children: [:])
            let invalidGenesisBlock = invalidGenesisArtifact!.toGenesis()
            
            let validAccountAction = AccountType(address: addressDigest, oldBalance: Digest(0), newBalance: totalPremine)
            let validTransactionArtifact0 = TransactionArtifactType(actions: [validAccountAction.toAction()], fee: Digest(0), previousHash: nil, publicKeySignatures: Mapping<Data, Data>(), homesteadState: homesteadStateObject0, parentHomesteadState: nil, parentReceipts: [], publicKey: publicKey.toData(), privateKey: privateKey.toData())
            let validGenesisArtifact = BlockArtifactType(transactionArtifacts: [validTransactionArtifact0!], definitionArtifact: definition!, nextDifficulty: Digest.max, index: Digest(0), timestamp: Double(1000), previousBlock: nil, homestead: homesteadState0.core.digest, parent: nil, nonce: Digest(0), children: [:])
            let validGenesisBlock = validGenesisArtifact!.toGenesis()

            it("it should fail if reward of genesis is greater than premine") {
                expect(invalidGenesisBlock).toNot(beNil())
                expect(invalidGenesisBlock!.verifyAllForGenesis()).to(beFalse())
                expect(validGenesisBlock).toNot(beNil())
                expect(validGenesisBlock!.verifyAllForGenesis()).to(beTrue())
            }
        }
    }
}
