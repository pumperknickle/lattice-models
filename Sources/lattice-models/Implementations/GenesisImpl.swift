import Foundation
import Bedrock

public struct GenesisImpl: Codable {
    private let rawDirectory: String!
    private let rawGenesisBinary: [Bool]!
    
    public init(directory: String, genesisBinary: [Bool]) {
        self.rawDirectory = directory
        self.rawGenesisBinary = genesisBinary
    }
}

extension GenesisImpl: ActionEncodable {
    public typealias ActionType = ActionImpl
}

extension GenesisImpl: Genesis {
    public var directory: String { return rawDirectory }
    public var genesisBinary: [Bool] { return rawGenesisBinary }
}
