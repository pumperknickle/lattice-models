import Foundation
import Nimble
import Quick
import AwesomeDictionary
import AwesomeTrie
import Bedrock
@testable import lattice_models

final class ActionSpec: QuickSpec {
    override func spec() {
        describe("Accounts") {
            typealias AccountType = AccountImpl
            typealias Digest = AccountImpl.Digest
            let account = AccountType(address: Digest(0), oldBalance: Digest(0), newBalance: Digest(10))
            let fullCircle = AccountType(action: account.toAction())
            it("should convert into an action") {
                expect(account.toAction()).toNot(beNil())
                expect(fullCircle).toNot(beNil())
                expect(try! JSONEncoder().encode(fullCircle!)).to(equal(try! JSONEncoder().encode(account)))
            }
        }
        describe("Deposits") {
            typealias DepositType = DepositImpl
            typealias DemandType = DepositType.DemandType
            typealias Digest = DemandType.Digest
            let demand = DemandType(nonce: Digest.random(), recipient: Digest(1), amount: Digest(10))
            let deposit = DepositType(demand: demand, oldBalance: Digest(0), newBalance: Digest(20))
            let fullCircle = DepositType(action: deposit.toAction())
            it("should convert into an action") {
                expect(deposit.toAction()).toNot(beNil())
                expect(fullCircle).toNot(beNil())
                expect(try! JSONEncoder().encode(fullCircle!)).to(equal(try! JSONEncoder().encode(deposit)))
            }
        }
        describe("Genesis") {
            typealias GenesisType = GenesisImpl
            let genesis = GenesisType(directory: "hello world", genesisBinary: [true])
            let fullCircle = GenesisType(action: genesis.toAction())
            it("should convert into an action") {
                expect(genesis.toAction()).toNot(beNil())
                expect(fullCircle).toNot(beNil())
                expect(try! JSONEncoder().encode(fullCircle!)).to(equal(try! JSONEncoder().encode(genesis)))
            }
        }
        describe("Peer") {
            typealias PeerType = PeerImpl
            typealias Digest = PeerType.Digest
            typealias SendableType = PeerImpl.SendableType
            
            let sendable = SendableType(ip: "192.168.2.2", port: 12)
            let peer = PeerType(address: Digest(10), old: nil, new: sendable)
            let fullCircle = PeerType(action: peer.toAction())
            it("should convert into an action") {
                expect(peer.toAction()).toNot(beNil())
                expect(fullCircle).toNot(beNil())
                expect(try! JSONEncoder().encode(fullCircle!)).to(equal(try! JSONEncoder().encode(peer)))
            }
        }
        describe("Receipt") {
            typealias ReceiptType = ReceiptImpl
            typealias DemandType = ReceiptType.DemandType
            typealias Digest = ReceiptImpl.Digest
            let demand = DemandType(nonce: Digest.random(), recipient: Digest(1), amount: Digest(10))
            let receipt = ReceiptType(sender: Digest(0), demand: demand)
            let fullCircle = ReceiptType(action: receipt.toAction())
            it("should convert into an action") {
                expect(receipt.toAction()).toNot(beNil())
                expect(fullCircle).toNot(beNil())
                expect(try! JSONEncoder().encode(fullCircle!)).to(equal(try! JSONEncoder().encode(receipt)))
            }
        }
        describe("Seed") {
            typealias SeedType = SeedImpl
            typealias SendableType = PeerImpl.SendableType
            let sendable = SendableType(ip: "192.168.2.2", port: 12)
            let seed = SeedType(directory: "hello world", oldSeeds: nil, newSeeds: [sendable])
            let fullCircle = SeedType(action: seed.toAction())
            it("should convert into an action") {
                expect(seed.toAction()).toNot(beNil())
                expect(fullCircle).toNot(beNil())
                expect(try! JSONEncoder().encode(fullCircle!)).to(equal(try! JSONEncoder().encode(seed)))
            }
        }
    }
}
