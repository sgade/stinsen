import Foundation
import SwiftUI

/// The TabCoordinatable is used to represent a coordinator with a TabView
public protocol TabCoordinatable: Coordinatable {
    typealias Route = TabRoute
    typealias Router = TabRouter<Self>
    associatedtype RouterStoreType

    var routerStorable: RouterStoreType { get }

    var child: TabChild { get }

    associatedtype CustomizeViewType: View

    /**
     Implement this function if you wish to customize the view on all views and child coordinators, for instance, if you wish to change the `tintColor` or inject an `EnvironmentObject`.

     - Parameter view: The input view.

     - Returns: The modified view.
     */
    func customize(_ view: AnyView) -> CustomizeViewType

    /**
     Searches the tabbar for the first route that matches the route and makes it the active tab.

     - Parameter route: The route that will be focused.
     */
    @discardableResult func focusFirst<Output: Coordinatable>(
        _ route: KeyPath<Self, Content<Self, Output>>
    ) -> Output
    
    /**
     Searches the tabbar for the first route that matches the route and makes it the active tab.

     - Parameter route: The route that will be focused.
     */
    @discardableResult func focusFirst<Output: View>(
        _ route: KeyPath<Self, Content<Self, Output>>
    ) -> Self
}

public extension TabCoordinatable {
    var routerStorable: Self {
        get {
            self
        }
    }

    func canDismissChild<T: Coordinatable>(_ coordinator: T) -> Bool {
        false
    }

    /// A tab cannot be dismissed. To show other content, focus another tab, or dismiss the tab coordinator itself.
    @discardableResult func dismissChild<T: Coordinatable>(coordinator: T, action: (() -> Void)?) -> Bool {
        reportMisuse("Cannot dismiss \(type(of: coordinator)), because it is a tab of \(type(of: self)).")
        return false
    }
    
    var parent: ChildDismissable? {
        get {
            return child.parent
        } set {
            child.parent = newValue
        }
    }
    
    internal func setupAllTabs() {
        var all: [TabChildItem] = []
        
        for abs in self.child.startingItems {
            let ina = self[keyPath: abs]
            
            if let val = ina as? Outputable {
                all.append(
                    TabChildItem(
                        presentable: val.using(coordinator: self),
                        keyPathIsEqual: {
                            ($0 as? AnyKeyPath) == abs
                        },
                        tabItem: { [weak self] in
                            guard let self else { return AnyView(EmptyView()) }
                            return val.tabItem(active: $0, coordinator: self)
                        },
                        onTapped: { [weak self] isRepeat in
                            guard let self else { return }
                            val.onTapped(isRepeat, coordinator: self)
                        }
                    )
                )
            }
        }
        
        self.child.allItems = all
    }
    
    func customize(_ view: AnyView) -> some View {
        return view
    }

    func view() -> AnyView {
        AnyView(
            TabCoordinatableView(
                paths: self.child.startingItems,
                coordinator: self,
                customize: customize
            )
        )
    }
    
    /// Makes the tab of `route` the active tab and returns its coordinator.
    ///
    /// If `route` is not a tab of this coordinator, the active tab does not change.
    /// The function then returns a new coordinator that is not shown, and logs a fault.
    @discardableResult func focusFirst<Output: Coordinatable>(
        _ route: KeyPath<Self, Content<Self, Output>>
    ) -> Output {
        if let tab = tab(of: route), let output = tab.item.presentable as? Output {
            self.child.activeTab = tab.index
            return output
        }

        reportMisuse("\(route) is not a tab of \(type(of: self)). The returned coordinator is not shown.")
        return self[keyPath: route].closure(self)()
    }

    /// Makes the tab of `route` the active tab. If `route` is not a tab, the active tab does not change.
    @discardableResult func focusFirst<Output: View>(
        _ route: KeyPath<Self, Content<Self, Output>>
    ) -> Self {
        if let tab = tab(of: route) {
            self.child.activeTab = tab.index
        } else {
            reportMisuse("\(route) is not a tab of \(type(of: self)).")
        }

        return self
    }

    private func tab<Output>(of route: KeyPath<Self, Content<Self, Output>>) -> (index: Int, item: TabChildItem)? {
        if child.allItems == nil {
            setupAllTabs()
        }

        guard let items = child.allItems, let index = items.firstIndex(where: { $0.keyPathIsEqual(route) }) else {
            return nil
        }

        return (index, items[index])
    }
}
