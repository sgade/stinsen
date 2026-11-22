import SwiftUI
import Foundation

public class TabRouter<T>: Routable {
    /// The coordinator of the router. The router keeps it alive, so that a router is always safe to use.
    public let coordinator: T

    public init(coordinator: T) {
        self.coordinator = coordinator
    }
}

public extension TabRouter where T: TabCoordinatable {
    /**
     Searches the tabbar for the first route that matches the route and makes it the active tab.

     - Parameter route: The route that will be focused.
     */
    @discardableResult func focusFirst<Output: Coordinatable>(
        _ route: KeyPath<T, Content<T, Output>>
    ) -> Output {
        self.coordinator.focusFirst(route)
    }
    
    /**
     Searches the tabbar for the first route that matches the route and makes it the active tab.

     - Parameter route: The route that will be focused.
     */
    @discardableResult func focusFirst<Output: View>(
        _ route: KeyPath<T, Content<T, Output>>
    ) -> T {
        self.coordinator.focusFirst(route)
    }
}
