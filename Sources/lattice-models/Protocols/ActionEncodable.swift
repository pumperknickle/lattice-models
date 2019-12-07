public protocol ActionEncodable {
    associatedtype ActionType: Action
    init?(action: ActionType)
    func toAction() -> ActionType
}
