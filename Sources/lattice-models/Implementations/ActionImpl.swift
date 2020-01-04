import Foundation

public struct ActionImpl: Codable {
    private let rawKey: String!
    private let rawOld: Data?
    private let rawNew: Data?
    
    public init(key: String, old: Data?, new: Data?) {
        rawKey = key
        rawOld = old
        rawNew = new
    }
}

extension ActionImpl: Action {
    public var key: String { return rawKey }
    public var old: Data? { return rawOld }
    public var new: Data? { return rawNew }
}
