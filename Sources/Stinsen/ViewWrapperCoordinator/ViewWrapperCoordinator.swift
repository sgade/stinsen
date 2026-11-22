import Foundation
import SwiftUI

/// The ViewWrapperCoordinator puts the view of a child coordinator in a custom view.
open class ViewWrapperCoordinator<T: Coordinatable, V: View>: @MainActor Coordinatable {
    public func dismissChild<Child: Coordinatable>(coordinator: Child, action: (() -> Void)?) {
        guard let parent = self.parent else {
            assertionFailure("Can not dismiss a coordinator since no coordinator is presented.")
            return
        }
        
        parent.dismissChild(coordinator: self, action: action)
    }

    public weak var parent: ChildDismissable?
    public let child: T
    private let viewFactory: (any Coordinatable) -> (AnyView) -> V

    /// The stack of the child if the child is a `NavigationCoordinatable`.
    /// Its pushes then go into the `NavigationStack` that shows this coordinator.
    var childNavigationStack: AnyCoordinatorStack? {
        CoordinatorPath.navigationStack(of: child)
    }

    public func view() -> AnyView {
        AnyView(
            ViewWrapperCoordinatorView(coordinator: self, viewFactory(self))
        )
    }
    
    public init(_ childCoordinator: T, _ view: @escaping (AnyView) -> V) {
        self.child = childCoordinator
        self.viewFactory = { _ in { view($0) } }
        self.child.parent = self
    }
    
    public init(_ childCoordinator: T, _ view: @escaping (any Coordinatable) -> (AnyView) -> V) {
        self.child = childCoordinator
        self.viewFactory = view
        self.child.parent = self
    }
}

extension ViewWrapperCoordinator: WrappingCoordinator {}
