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
                it("should not verify") {
                    expect(reward).to(equal(Digest(Int(pow(Double(2), Double(10))))))
                    expect(invalidBlock).toNot(beNil())
                    expect(invalidBlock!.verifyAll()).to(beFalse())
                    expect(validBlock).toNot(beNil())
                    expect(validBlock!.verifyAll()).to(beTrue())
                }
            }
        }
    }
}
//
//let privateKey = """
//-----BEGIN RSA PRIVATE KEY-----
//MIIEowIBAAKCAQEAlznyd/pK9bVqC8JUv8q3SN8yCuk1vagIyHgF0MJPPIlU5fpX
//HyUKN60IaIjD4ujjHu0mDnmJo9rh4gkXlfymIWl5gAD1tQ6K4u9TwIOB7oowBKYG
//1xHNYBHZxP3pj/7rgKkQEvBZUrdBi4ss9wVvqjFK0wz7GiN8F2uxvR0foeqT/RV/
//HZoglhVmj2FwC2hHIQFCrOgmzmbtEEyvC+h9DaSr7h5d6UM5Konqktq6OaZCALbo
//IriaQnTjcyexcpSENLnPFMiNdUiOTQyXOKEI+ar59AdIpmEespwlQDFMka0MoxsX
//vr4tRmeyl49En0EqYYRH5AIeeblkHfPh/fiBXwIDAQABAoIBAAzJLHPyaIYPuZCW
//9J1moUp6/Hspro6Dd4KjizJUS2i937y2BsmuUwfUDGLyNUWpFRLXUCFnKzj8V57J
//0AGxY8ZtaYVmD2Aog5ueSoF7XO/zJQ4vj2J9sdSOjc/2+9ld30F4idBgG90/ez42
//HS4heoh0NHRVo6FZILPGOjfYD4Wb83L0gai+5kkhecDg8UWtVSzYbIyhB7G7SeWW
//ogyQrugQbptB6TYTnoPsmraouU2aVEMOhC5sHLk3s7YGKce1UWJB95SUBSNE3itr
//ljLkYBP42gjEzvc0sfNrXuxRXiQyrD+Go5lptsWE7aBpJk9nsXFsN1Kl6FqBTn+s
//eFJSC1kCgYEAx1/AVsY2Isc96go9Owfz+PTrR8/PaWbcrjZLMmq5G7f0rTCRjUc9
//MhYu2AiD1khauZD3TBsspO6WKALAJJlsv2GCuBCo42tUNz1JWystIYcfe64u3zaz
//HVWV3H6mwfoND4EMoT0cytwadpf6629ql/b0o/vRwXAjxP2LTDnuIu0CgYEAwi1v
//jmNI3raY46uv6X4LQEHpSQiLiNazVd2J724ZXeGdZCqDsRQCZYkZqyFZtd1yEiTd
//6Ah1CS3H3a/MUt80AgPNb4MaRZWetZNavtNZ/JdqpN5FFsgrnmU7xOmhV+4HjQpE
//pqU8qFpUey+L6A+iyZ8D2P+OVhaVKM5+2qlF7/sCgYA/x2S7HZtR0tT+mpnt2WR1
//nrvpdBQQzsQHwvyZO0TOFjHieWgGfuSXsjr4BvlNwkWrmTFTGlpUxLIqSH749k+w
//hVwQz9uHLN168lMWJCDC2fv7T8RUyaXQ24EeUTG9WeV1sT2+EtO0HWclywaM7E54
//IJswHi2CqQH4UXePQfTpHQKBgQC284BMNBeQX5Kl0DmqUWvgWzml6jst7ryBhn5T
//7PRRlCVrHvN9gFDRwd9BcebIh6DWn43E9VLwFwZdRSnKWyrxSwvgqTGzpkkm43N4
//oEIEz9VXCWUnFeqjDtbFrSqrYkYTCT2tlboVFSbL+fxj5XeHaB+D8ST2z8gx7n1v
//IFYYyQKBgClVy+MWDCJPMm2dRk6AEKGdAs4yiO5Sb710t29kvxKtZzUuyFCRZAtt
//ENIcr0ZvAo6rQwP+DgsvYdKeUQbQaKDR82HkT/SUNPergdp5SFaR2C2XpRyYHh5q
//Xj9uKUw0ExH06Qa5GGAcVhcw0PyGtM09Mu93iQbMUukBqQGQN5Z3
//-----END RSA PRIVATE KEY-----
//"""
//
//let publicKey = """
//-----BEGIN PUBLIC KEY-----
//MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlznyd/pK9bVqC8JUv8q3
//SN8yCuk1vagIyHgF0MJPPIlU5fpXHyUKN60IaIjD4ujjHu0mDnmJo9rh4gkXlfym
//IWl5gAD1tQ6K4u9TwIOB7oowBKYG1xHNYBHZxP3pj/7rgKkQEvBZUrdBi4ss9wVv
//qjFK0wz7GiN8F2uxvR0foeqT/RV/HZoglhVmj2FwC2hHIQFCrOgmzmbtEEyvC+h9
//DaSr7h5d6UM5Konqktq6OaZCALboIriaQnTjcyexcpSENLnPFMiNdUiOTQyXOKEI
//+ar59AdIpmEespwlQDFMka0MoxsXvr4tRmeyl49En0EqYYRH5AIeeblkHfPh/fiB
//XwIDAQAB
//-----END PUBLIC KEY-----
//"""
//
