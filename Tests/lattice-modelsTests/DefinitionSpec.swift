import Foundation
import Nimble
import Quick
import AwesomeDictionary
import AwesomeTrie
import Regenerate
@testable import lattice_models

final class DefinitionSpec: QuickSpec {
    override func spec() {
        typealias BlockArtifactType = BlockArtifactImpl
        typealias DefinitionArtifactType = BlockArtifactType.DefinitionArtifactType
        typealias Digest = BlockArtifactType.Digest
        
        
        let initialRewardExponent = 10
        let definitionArtifact = DefinitionArtifactType(size: Digest(1000000), premine: Digest(10), period: Double(10), initialRewardExponent: initialRewardExponent, filters: ["var transactionFilter = function(value) { return true; }"])
        let definition = definitionArtifact!.toDefinition()!

        describe("reward per block") {
            it("should be 2 ** initial reward exponent") {
                let initialReward = Digest.twoTothePowerOf(10)
                expect(initialReward).to(equal(Digest(1024)))
                expect(definition.rewardAtBlock(index: Digest(0))).to(equal(initialReward))
            }
            it("premine amount should be equal to number of block rewards in premine") {
                
            }
        }
    }
}
