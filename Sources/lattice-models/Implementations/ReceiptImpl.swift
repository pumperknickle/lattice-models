import Foundation
import Bedrock

public struct ReceiptImpl: Codable {
    private let rawSender: Digest!
    private let rawDemand: DemandType!
    
    public init(sender: UInt256, demand: DemandImpl) {
        rawSender = sender
        rawDemand = demand
    }
}

extension ReceiptImpl: ActionEncodable {
    public typealias ActionType = ActionImpl
}

extension ReceiptImpl: Receipt {
    public typealias DemandType = DemandImpl
    
    public var sender: UInt256 { return rawSender }
    public var demand: DemandImpl { return rawDemand }
}
