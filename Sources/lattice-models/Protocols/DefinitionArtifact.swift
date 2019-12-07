import Foundation
import Bedrock
import JavaScriptCore
import Regenerate
import CryptoStarterPack
import AwesomeTrie
import AwesomeDictionary

public protocol DefinitionArtitact: RGArtifact {
    associatedtype Digest
    associatedtype DefinitionType: Definition where DefinitionType.Digest == Digest
    
    associatedtype FiltersScalar: RGScalar where FiltersScalar.T == [String]
    associatedtype FiltersAddress where FiltersAddress.Artifact == FiltersScalar, FiltersAddress.Digest == Digest
    associatedtype FiltersArray: RGArray where FiltersArray.Element == FiltersAddress
    associatedtype FiltersArrayAddress: Addressable where FiltersArrayAddress.Artifact == FiltersArray, FiltersArrayAddress.Digest == Digest
    
    var size: Digest! { get }
    var premine: Digest! { get }
    var period: Double! { get }
    var initialRewardExponent: Int! { get }
    var filterRoot: FiltersArrayAddress! { get }
    
    static func filterProperty() -> String
    
    func toDefinition() -> DefinitionType?
    
    init(size: Digest, premine: Digest, period: Double, initialRewardExponent: Int, filterRoot: FiltersArrayAddress)
}

public extension DefinitionArtitact {
    func changing(size: Digest? = nil, premine: Digest? = nil, period: Double? = nil, initialRewardExponent: Int? = nil, filterRoot: FiltersArrayAddress? = nil) -> Self {
        return Self(size: size ?? self.size, premine: premine ?? self.premine, period: period ?? self.period, initialRewardExponent: initialRewardExponent ?? self.initialRewardExponent, filterRoot: filterRoot ?? self.filterRoot)
    }
    
    static func filterProperty() -> String {
        return "filter"
    }
    
    static func properties() -> [String] {
        return [filterProperty()]
    }
    
    func set(property: String, to child: CryptoBindable) -> Self? {
        switch property {
        case Self.filterProperty():
            guard let newChild = child as? FiltersArrayAddress else { return nil }
            return changing(filterRoot: newChild)
        default:
            return nil
        }
    }
    
    func get(property: String) -> CryptoBindable? {
        switch property {
        case Self.filterProperty():
            return filterRoot
        default:
            return nil
        }
    }
    
    func toDefinition() -> DefinitionType? {
        guard let filters = extractFilters() else { return nil }
        return DefinitionType(size: size, premine: premine, period: period, initialRewardExponent: initialRewardExponent, transactionFilters: filters)
    }
    
    func extractFilters() -> [String]? {
        let filters = filterRoot.artifact?.children.elements().map { $0.1.artifact?.scalar }
        guard let allFilters = filters else { return nil }
        let filterSet = allFilters.reduce(Set([])) { (result, entry) -> Set<String>? in
            guard let result = result else { return nil }
            guard let entry = entry else { return nil }
            return result.union(entry)
        }
        guard let finalFilters = filterSet else { return nil }
        return Array(finalFilters)
    }
}
