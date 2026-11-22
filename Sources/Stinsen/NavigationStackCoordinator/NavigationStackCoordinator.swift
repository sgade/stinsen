import Foundation
import SwiftUI

/// The NavigationStackCoordinator puts a coordinator in a `NavigationStack`.
///
/// If the child is a `NavigationCoordinatable`, the routes that it and its child coordinators push become the path of the `NavigationStack`.
public class NavigationStackCoordinator<T: Coordinatable>: ViewWrapperCoordinator<T, AnyView> {
    public init(_ childCoordinator: T) {
        super.init(childCoordinator) { view in
            // Find the stack here, so that the root of the child is made when the view shows, as in other coordinators.
            if let childStack = CoordinatorPath.navigationStack(of: childCoordinator) {
                AnyView(NavigationHostView(stack: childStack, anchor: -1, anchorItem: nil))
            } else {
                AnyView(SwiftUI.NavigationStack { view })
            }
        }
    }

    /// The child has its own `NavigationStack`, so its pushes do not go into an enclosing one.
    override var childNavigationStack: AnyCoordinatorStack? {
        nil
    }

    @available(*, unavailable, message: "The view of a NavigationStackCoordinator cannot be customized.")
    public override init(_ childCoordinator: T, _ view: @escaping (AnyView) -> AnyView) {
        super.init(childCoordinator, view)
    }

    @available(*, unavailable, message: "The view of a NavigationStackCoordinator cannot be customized.")
    public override init(_ childCoordinator: T, _ view: @escaping (any Coordinatable) -> (AnyView) -> AnyView) {
        super.init(childCoordinator, view)
    }
}

@available(*, deprecated, renamed: "NavigationStackCoordinator")
public typealias NavigationViewCoordinator<T: Coordinatable> = NavigationStackCoordinator<T>
