import Foundation
import Bedrock
import Socket

public struct SendableImpl: Codable {
    private let rawIP: String!
    private let rawPort: Int!
    
    public init(ip: String, port: Int) {
        rawIP = ip
        rawPort = port
    }
}

extension SendableImpl: Sendable {
    public func send(data: [Bool]) {
        let rawData = Data.convert(data)
        guard let address = Socket.createAddress(for: rawIP, on: Int32(rawPort)) else { return }
        guard let socket = try? Socket.create(family: .inet, type: .datagram, proto: .udp) else { return }
        _ = try? socket.write(from: rawData, to: address)
    }
}
