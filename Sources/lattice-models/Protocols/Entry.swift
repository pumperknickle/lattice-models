import Foundation
import Bedrock

public protocol Entry: Codable, ActionEncodable {
    associatedtype Digest: FixedWidthInteger, Stringable

    var oldBalance: Digest { get }
    var newBalance: Digest { get }
}
