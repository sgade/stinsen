import Foundation
import SwiftUI

/// A type-erased coordinator.
public final class AnyCoordinator: @MainActor Coordinatable {
    private let makeView: () -> AnyView
    private let getParent: () -> ChildDismissable?
    private let setParent: (ChildDismissable?) -> Void
    private let dismissChildCoordinator: (any Coordinatable, (() -> Void)?) -> Bool
    private let canDismissChildCoordinator: (any Coordinatable) -> Bool
    private let getID: () -> String

    public var parent: ChildDismissable? {
        get {
            getParent()
        } set {
            setParent(newValue)
        }
    }

    @discardableResult public func dismissChild<T: Coordinatable>(coordinator: T, action: (() -> Void)?) -> Bool {
        dismissChildCoordinator(coordinator, action)
    }

    public func canDismissChild<T: Coordinatable>(_ coordinator: T) -> Bool {
        canDismissChildCoordinator(coordinator)
    }

    public func view() -> AnyView {
        makeView()
    }

    public var id: String {
        getID()
    }

    public init<Base: Coordinatable>(_ base: Base) {
        makeView = { base.view() }
        getParent = { base.parent }
        setParent = { base.parent = $0 }
        dismissChildCoordinator = { coordinator, action in
            Self.dismissChild(coordinator, of: base, action: action)
        }
        canDismissChildCoordinator = { coordinator in
            Self.canDismiss(coordinator, of: base)
        }
        getID = { base.id }
    }

    private static func canDismiss<Base: Coordinatable, Child: Coordinatable>(_ child: Child, of base: Base) -> Bool {
        base.canDismissChild(child)
    }

    private static func dismissChild<Base: Coordinatable, Child: Coordinatable>(
        _ child: Child,
        of base: Base,
        action: (() -> Void)?
    ) -> Bool {
        base.dismissChild(coordinator: child, action: action)
    }
}
