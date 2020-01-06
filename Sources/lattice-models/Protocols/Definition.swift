import Foundation
import Bedrock

public protocol Definition {
    associatedtype Digest: FixedWidthInteger, Stringable
    
    // defines maximum number of bits actions can add to the world state
    var size: Digest! { get }
    // defines the total blocks premined allocated to creators
    var premine: Digest! { get }
    // defines the total number of seconds between blocks
    var period: Double! { get }
    // defines initial award amount 2 ** rewardExponent
    var initialRewardExponent: Int! { get }
    var transactionFilters: [String]! { get }
    // total reward allocated to creators
    func premineAmount() -> Digest
    func rewardAtBlock(index: Digest) -> Digest
    
    init(size: Digest, premine: Digest, period: Double, initialRewardExponent: Int, transactionFilters: [String])
}

public extension Definition {
    // defines total award amount 2 ** totalExponent
    static func totalExponent() -> Int {
        return Digest.bitWidth
    }
    
    func verifyNewDifficulty(previousDifficulty: Digest, newDifficulty: Digest, blockInterval: Double) -> Bool {
        let newDifficultyDivided = newDifficulty.quotientAndRemainder(dividingBy: Digest(blockInterval))
        let previousDifficultyDivided = previousDifficulty.quotientAndRemainder(dividingBy: Digest(period))
        if newDifficultyDivided.quotient == previousDifficultyDivided.quotient { return newDifficultyDivided.remainder <= previousDifficultyDivided.remainder }
        return newDifficultyDivided.quotient < previousDifficultyDivided.quotient
    }

    func halvingExponent() -> Int {
        return Self.totalExponent() - initialRewardExponent - 1
    }
    
    func halvingInterval() -> Digest {
        return Digest.twoTothePowerOf(halvingExponent())
    }
    
    func totalHalvings() -> Int {
        return initialRewardExponent + 1
    }
    
    func totalRewarded() -> Digest {
        return halvingInterval() * Digest(totalHalvings())
    }
    
    func totalRewards(count: Digest) -> Digest {
        return totalRewards(count: count, currentTotal: Digest(0), currentReward: Digest.twoTothePowerOf(initialRewardExponent), halving: halvingInterval())
    }
    
    func totalRewards(count: Digest, currentTotal: Digest, currentReward: Digest, halving: Digest) -> Digest {
        if currentReward == Digest(1) { return currentTotal + halving }
        if count <= halving { return currentTotal + (currentReward * count) }
        return totalRewards(count: count - halving, currentTotal: currentTotal + (currentReward * halving), currentReward: currentReward / 2, halving: halving)
    }
    
    func rewardExponent(index: Digest) -> Int {
        return rewardExponent(currentExponent: initialRewardExponent, index: index, halvingInterval: halvingInterval())
    }
    
    func rewardExponent(currentExponent: Int, index: Digest, halvingInterval: Digest) -> Int {
        if currentExponent == 0 { return 0 }
        if index <= halvingInterval { return currentExponent }
        return rewardExponent(currentExponent: currentExponent - 1, index: index - halvingInterval, halvingInterval: halvingInterval)
    }
    
    func premineAmount() -> Digest {
        return totalRewards(count: premine)
    }
    
    func rewardExponentAtBlock(index: Digest) -> Int {
        return rewardExponent(index: index + premine)
    }
    
    func rewardAtBlock(index: Digest) -> Digest {
        return Digest.twoTothePowerOf(rewardExponentAtBlock(index: index))
    }
}
