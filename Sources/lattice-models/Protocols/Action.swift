import Foundation
import Bedrock
import Regenerate

public protocol Action: DataEncodable {
    var key: String { get }
    var old: Data? { get }
    var new: Data? { get }

    func stateDelta() -> Int

    init(key: String, old: Data?, new: Data?)
}

public extension Action {
    func toData() -> Data {
        return try! JSONEncoder().encode(self)
    }
    
    init?(data: Data) {
        guard let newSelf = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = newSelf
    }
    
    func proofType() -> TransitionProofType {
        if new == nil { return .deletion }
        if old == nil { return .creation }
        return .mutation
    }
    
    func verify() -> Bool {
        if key.isEmpty { return false }
        return old != nil || new != nil
    }
    
    func stateDelta() -> Int {
        guard let old = old else { return key.count + (new?.count ?? 0) }
        guard let new = new else { return -old.count - key.count }
        return new.count - old.count
    }
}

public extension Sequence where Element: Action {
    func stateDelta<T: FixedWidthInteger>() -> T {
        return stateDelta(initial: T(0))
    }
    
    func stateDelta<T: FixedWidthInteger>(initial: T) -> T {
        return map { T($0.stateDelta()) }.reduce(initial, +)
    }
}
