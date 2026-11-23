import Foundation
import SwiftUI

protocol Outputable {
    func using(coordinator: Any) -> ViewPresentable
    func tabItem(active: Bool, coordinator: Any) -> AnyView
    func onTapped(_ isRepeat: Bool, coordinator: Any)
}

public class Content<T: TabCoordinatable, Output: ViewPresentable>: Outputable {
    
    func tabItem(active: Bool, coordinator: Any) -> AnyView {
        guard let coordinator = coordinator as? T else {
            return AnyView(EmptyView())
        }

        return self.tabItem(coordinator)(active)
    }

    func using(coordinator: Any) -> ViewPresentable {
        guard let coordinator = coordinator as? T else {
            reportMisuse("The tab of \(T.self) got a coordinator of type \(type(of: coordinator)). Stinsen shows an empty view.")
            return AnyView(EmptyView())
        }

        let closureOutput = self.closure(coordinator)()
        self.output = closureOutput
        return closureOutput
    }

    func onTapped(_ isRepeat: Bool, coordinator: Any) {
        guard let coordinator = coordinator as? T, let output else {
            return
        }

        self.onTapped(coordinator)(isRepeat, output)
    }
    
    let closure: ((T) -> (() -> Output))
    let tabItem: ((T) -> ((Bool) -> AnyView))
    let onTapped: ((T) -> ((Bool, Output) -> Void))
    
    private var output: Output?
    
    init<TabItem: View>(
        closure: @escaping ((T) -> (() -> Output)),
        tabItem: @escaping ((T) -> ((Bool) -> TabItem)),
        onTapped: @escaping ((T) -> ((Bool, Output) -> Void))
    ) {
        self.closure = closure
        self.tabItem = { coordinator in
            return {
                AnyView(tabItem(coordinator)($0))
            }
        }
        self.onTapped = { coordinator in
            onTapped(coordinator)
        }
    }
}

@propertyWrapper public class TabRoute<T: TabCoordinatable, Output: ViewPresentable> {
    public var wrappedValue: Content<T, Output>
    
    fileprivate init(standard: Content<T, Output>) {
        self.wrappedValue = standard
    }
}

extension TabRoute where T: TabCoordinatable, Output == AnyView {
    public convenience init<ViewOutput: View, TabItem: View>(
        wrappedValue: @escaping ((T) -> (() -> ViewOutput)),
        tabItem: @escaping ((T) -> ((Bool) -> TabItem))
    ) {
        self.init(
            standard: Content(
                closure: { coordinator in { AnyView(wrappedValue(coordinator)()) }},
                tabItem: tabItem,
                onTapped: { _ in { _, _ in }}
            )
        )
    }
    
    public convenience init<ViewOutput: View, TabItem: View>(
        wrappedValue: @escaping ((T) -> (() -> ViewOutput)),
        tabItem: @escaping ((T) -> ((Bool) -> TabItem)),
        onTapped: @escaping ((T) -> ((Bool, Output) -> Void))
    ) {
        self.init(standard: Content(
            closure: { coordinator in { AnyView(wrappedValue(coordinator)()) }},
            tabItem: tabItem,
            onTapped: onTapped))
    }
}

extension TabRoute where T: TabCoordinatable, Output: Coordinatable {
    public convenience init<TabItem: View>(
        wrappedValue: @escaping ((T) -> (() -> Output)),
        tabItem: @escaping ((T) -> ((Bool) -> TabItem))
    ) {
        self.init(
            standard: Content(
                closure: { coordinator in { wrappedValue(coordinator)() }},
                tabItem: tabItem,
                onTapped: { _ in { _, _ in }}
            )
        )
    }
    
    public convenience init<TabItem: View>(
        wrappedValue: @escaping ((T) -> (() -> Output)),
        tabItem: @escaping ((T) -> ((Bool) -> TabItem)),
        onTapped: @escaping ((T) -> ((Bool, Output) -> Void))
    ) {
        self.init(standard: Content(
            closure: { coordinator in { wrappedValue(coordinator)() }},
            tabItem: tabItem,
            onTapped: onTapped))
    }
}
