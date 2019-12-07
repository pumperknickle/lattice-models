import Foundation
import Bedrock
import Regenerate

public protocol Action: BinaryEncodable {
    var key: [Bool] { get }
    var old: [Bool] { get }
    var new: [Bool] { get }

    func stateDelta() -> Int

    init(key: [Bool], old: [Bool], new: [Bool])
}

public extension Action {
    func toBoolArray() -> [Bool] {
        return (try! JSONEncoder().encode(self)).toBoolArray()
    }
    
    init?(raw: [Bool]) {
        guard let data = Data(raw: raw) else { return nil }
        guard let newSelf = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = newSelf
    }
    
    func proofType() -> TransitionProofType {
        if new.isEmpty { return .deletion }
        if old.isEmpty { return .creation }
        return .mutation
    }
    
    func verify() -> Bool {
        if key.isEmpty { return false }
        return (!old.isEmpty || !new.isEmpty)
    }
    
    func stateDelta() -> Int {
        if old.isEmpty { return key.count + new.count }
        if new.isEmpty { return -old.count - key.count }
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
