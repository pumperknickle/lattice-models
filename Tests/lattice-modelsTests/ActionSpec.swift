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
                expect(fullCircle!.address).to(equal(account.address))
                expect(fullCircle!.newBalance).to(equal(account.newBalance))
                expect(fullCircle!.oldBalance).to(equal(account.oldBalance))
            }
            it("should have string convertible key") {
                expect(String(raw: account.toAction().key)).toNot(beNil())
            }
        }
    }
}
