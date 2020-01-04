import Foundation
import Bedrock

public protocol Demand: DataEncodable {
    associatedtype Digest: FixedWidthInteger, Stringable
    
    // nonce to create unique demand entity
    var nonce: Digest { get }
    // address to send currency to
    var recipient: Digest { get }
    // amount to send
    var amount: Digest { get }
    
    init(nonce: Digest, recipient: Digest, amount: Digest)
}

public extension Demand {
    init?(data: Data) {
        guard let demand = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = demand
    }
    
    func toData() -> Data {
        return try! JSONEncoder().encode(self)
    }
}
