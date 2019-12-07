import Foundation

public extension FixedWidthInteger {
    static func twoTothePowerOf(_ exponent: Int) -> Self {
        return Self.twoToThePowerOf(exponent, current: Self(1))
    }
    
    static func twoToThePowerOf(_ exponent: Int, current: Self) -> Self {
        if exponent == 0 { return current }
        return twoToThePowerOf(exponent - 1, current: current * 2)
    }
}
