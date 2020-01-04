import Foundation
import Bedrock

public struct GenesisImpl: Codable {
    private let rawDirectory: String!
    private let rawGenesisData: Data!
    
    public init(directory: String, genesisData: Data) {
        self.rawDirectory = directory
        self.rawGenesisData = genesisData
    }
}

extension GenesisImpl: ActionEncodable {
    public typealias ActionType = ActionImpl
}

extension GenesisImpl: Genesis {
    public var directory: String { return rawDirectory }
    public var genesisData: Data { return rawGenesisData }
}
