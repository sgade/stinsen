import Foundation
import Observation
import SwiftUI

struct TabChildItem {
    let presentable: ViewPresentable
    let keyPathIsEqual: (Any) -> Bool
    let tabItem: (Bool) -> AnyView
    let onTapped: (Bool) -> Void
}

/// Wrapper around childCoordinators
@Observable
public class TabChild {
    @ObservationIgnored weak var parent: ChildDismissable?
    public let startingItems: [AnyKeyPath]

    var activeItem: TabChildItem?

    @ObservationIgnored var allItems: [TabChildItem]!

    public var activeTab: Int {
        didSet {
            allItems[activeTab].onTapped(oldValue == activeTab)
            guard oldValue != activeTab else { return }
            activeItem = allItems[activeTab]
        }
    }

    public init(startingItems: [AnyKeyPath], activeTab: Int = 0) {
        self.startingItems = startingItems
        self.activeTab = activeTab
    }
}
