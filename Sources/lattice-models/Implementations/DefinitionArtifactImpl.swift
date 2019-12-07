import Foundation
import Bedrock
import Regenerate

public struct DefinitionArtifactImpl: Codable {
    private let rawSize: Digest!
    private let rawPremine: Digest!
    private let rawPeriod: Double!
    private let rawInitialRewardExponent: Int!
    private let rawFilterRoot: FiltersArrayAddress!
    
    public init(size: UInt256, premine: UInt256, period: Double, initialRewardExponent: Int, filterRoot: Address<DefinitionArtifactImpl.FiltersArray>) {
        rawSize = size
        rawPremine = premine
        rawPeriod = period
        rawInitialRewardExponent = initialRewardExponent
        rawFilterRoot = filterRoot
    }
}

extension DefinitionArtifactImpl: DefinitionArtitact {
    public typealias Digest = UInt256
    public typealias DefinitionType = DefinitionImpl
    public typealias FiltersScalar = Scalar<[String]>
    public typealias FiltersAddress = Address<FiltersScalar>
    public typealias FiltersArray = Array256<FiltersAddress>
    public typealias FiltersArrayAddress = Address<FiltersArray>
    
    public var size: Digest! { return rawSize }
    public var premine: Digest! { return rawPremine }
    public var period: Double! { return rawPeriod }
    public var initialRewardExponent: Int! { return rawInitialRewardExponent }
    public var filterRoot: FiltersArrayAddress! { return rawFilterRoot }
}
