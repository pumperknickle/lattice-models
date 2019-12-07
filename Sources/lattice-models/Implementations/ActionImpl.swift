import Foundation

public struct ActionImpl: Codable {
    private let rawKey: [Bool]!
    private let rawOld: [Bool]!
    private let rawNew: [Bool]!
    
    public init(key: [Bool], old: [Bool], new: [Bool]) {
        rawKey = key
        rawOld = old
        rawNew = new
    }
}

extension ActionImpl: Action {
    public var key: [Bool] { return rawKey }
    public var old: [Bool] { return rawOld }
    public var new: [Bool] { return rawNew }
}
