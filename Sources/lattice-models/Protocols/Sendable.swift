import Foundation
import Bedrock

public protocol Sendable: DataEncodable {
    func send(data: [Bool])
}

public extension Sendable {
    func toData() -> Data {
        return try! JSONEncoder().encode(self)
    }
    
    init?(data: Data) {
        guard let decoded = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = decoded
    }
}
