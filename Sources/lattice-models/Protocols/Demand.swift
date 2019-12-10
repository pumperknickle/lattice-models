import Foundation
import Bedrock

public protocol Demand: BinaryEncodable {
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
    init?(raw: [Bool]) {
        guard let demandData = Data(raw: raw) else { return nil }
        guard let demand = try? JSONDecoder().decode(Self.self, from: demandData) else { return nil }
        self = demand
    }
    
    func toBoolArray() -> [Bool] {
        return (try! JSONEncoder().encode(self)).toBoolArray()
    }
}
