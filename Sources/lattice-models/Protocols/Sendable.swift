import Foundation
import Bedrock

public protocol Sendable: BinaryEncodable {
    func send(data: [Bool])
}
